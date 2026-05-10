import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/model/harvest_slot_record.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/harvest_repository.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class HarvestSlotPage extends StatefulWidget {
  const HarvestSlotPage({super.key});

  @override
  State<HarvestSlotPage> createState() => _HarvestSlotPageState();
}

class _HarvestSlotPageState extends State<HarvestSlotPage> {
  final repository = HarvestRepository();
  final noticeController = TextEditingController();
  var options = <HarvestProductOption>[];
  HarvestProductOption? selectedOption;
  HarvestPredictionRecord? prediction;
  DateTime? confirmedStart;
  DateTime? confirmedEnd;
  int pastYieldKg = 420;
  String recentWeather = '평년 수준';
  String cultivationStatus = '양호';
  int confirmedReservableKg = 0;
  int confirmedPrice = 0;
  bool loading = true;
  bool predicting = false;
  bool opening = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    noticeController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final loaded = await repository.fetchProductOptions();
      if (!mounted) return;
      options = loaded;
      selectedOption = loaded.isEmpty ? null : loaded.first;
      _resetPredictionInputs();
      loading = false;
      setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = '수확 예측 정보를 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _createPrediction() async {
    final option = selectedOption;
    if (option == null) return;
    setState(() {
      predicting = true;
      prediction = null;
      errorMessage = null;
    });

    try {
      final created = await repository.createPrediction(
        option,
        pastYieldKg: pastYieldKg,
        recentWeather: recentWeather,
        cultivationStatus: cultivationStatus,
      );
      if (!mounted) return;
      setState(() {
        prediction = created;
        _applyPredictionDefaults(created, option);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => errorMessage = '수확 예측을 생성하지 못했습니다.');
    } finally {
      if (mounted) setState(() => predicting = false);
    }
  }

  Future<void> _openSlot() async {
    final option = selectedOption;
    final currentPrediction = prediction;
    if (option == null || currentPrediction == null) {
      showOwnerSnack(context, '수확 예측을 먼저 생성하세요.');
      return;
    }
    final start = confirmedStart;
    final end = confirmedEnd;
    if (start == null || end == null || end.isBefore(start)) {
      showOwnerSnack(context, '수확 시작일과 종료일을 확인하세요.');
      return;
    }
    if (confirmedReservableKg <= 0 || confirmedPrice <= 0) {
      showOwnerSnack(context, '예약 가능 수량과 판매가를 확인하세요.');
      return;
    }

    showConfirmAction(
      context: context,
      title: '수확 슬롯 열기',
      message:
          '${option.product.name} ${confirmedReservableKg}kg을 ${_dateLabel(start)}-${_dateLabel(end)} 기간에 열까요?',
      confirmLabel: '열기',
      onConfirm: () async {
        setState(() => opening = true);
        try {
          await repository.createOpenSlot(
            option: option,
            prediction: currentPrediction,
            confirmedHarvestStart: _apiDate(start),
            confirmedHarvestEnd: _apiDate(end),
            confirmedReservableKg: confirmedReservableKg,
            confirmedPrice: confirmedPrice,
            customerNotice: noticeController.text.trim().isEmpty
                ? '${option.product.name} 예약 가능 수량을 열었습니다.'
                : noticeController.text.trim(),
          );
          if (!mounted) return;
          showInfoAction(
            context: context,
            title: '수확 슬롯 열기',
            message: '예약 가능한 수확 슬롯을 열었습니다.',
          );
        } on ApiException catch (error) {
          if (!mounted) return;
          showInfoAction(
            context: context,
            title: '수확 슬롯 열기',
            message: error.message,
          );
        } catch (_) {
          if (!mounted) return;
          showInfoAction(
            context: context,
            title: '수확 슬롯 열기',
            message: '수확 슬롯을 열지 못했습니다.',
          );
        } finally {
          if (mounted) setState(() => opening = false);
        }
      },
    );
  }

  void _applyPredictionDefaults(
    HarvestPredictionRecord record,
    HarvestProductOption option,
  ) {
    confirmedStart = DateTime.tryParse(record.predictedHarvestStart);
    confirmedEnd = DateTime.tryParse(record.predictedHarvestEnd);
    confirmedReservableKg = record.suggestedReservableMaxKg.round();
    confirmedPrice = record.recommendedPrice;
    noticeController.text =
        '${option.product.name} ${ProductRecord.packageLabel(option.product.packageUnitKg)} 예약을 시작합니다.';
  }

  void _resetPredictionInputs() {
    final option = selectedOption;
    if (option == null) return;
    pastYieldKg = (option.product.packageUnitKg * (option.product.stockKg + 80))
        .round()
        .clamp(100, 100000)
        .toInt();
    recentWeather = '평년 수준';
    cultivationStatus = '양호';
    prediction = null;
    confirmedStart = null;
    confirmedEnd = null;
    confirmedReservableKg = 0;
    confirmedPrice = option.product.price;
    noticeController.clear();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? confirmedStart ?? now
        : confirmedEnd ?? confirmedStart ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        confirmedStart = picked;
        if (confirmedEnd != null && confirmedEnd!.isBefore(picked)) {
          confirmedEnd = picked;
        }
      } else {
        confirmedEnd = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPrediction = prediction;
    return Scaffold(
      body: AppScaffold(
        title: '수확 예측',
        leading: ActionChipIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        children: [
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!loading && errorMessage != null)
            DataTile(
              icon: Icons.error_outline,
              title: '수확 예측 연결 실패',
              subtitle: errorMessage!,
              badge: '재시도',
              badgeColor: const Color(0xffFFE1DD),
              onTap: _loadOptions,
            ),
          if (!loading && options.isEmpty)
            const NoticeBox(color: Color(0xffFFF1C7), text: '예측할 상품이 없습니다.'),
          if (!loading && options.isNotEmpty) ...[
            LabeledDropdown(
              label: '상품',
              value: selectedOption?.product.name ?? '',
              items: [for (final option in options) option.product.name],
              onChanged: (value) {
                final next = options.firstWhere(
                  (option) => option.product.name == value,
                  orElse: () => options.first,
                );
                setState(() {
                  selectedOption = next;
                  _resetPredictionInputs();
                });
              },
            ),
            const SectionHeader(title: '예측 입력값'),
            LabeledNumberStepper(
              label: '최근 기준 수확량',
              value: pastYieldKg,
              min: 100,
              max: 100000,
              step: 10,
              suffixText: 'kg',
              onChanged: (value) {
                setState(() {
                  pastYieldKg = value;
                  prediction = null;
                });
              },
            ),
            LabeledDropdown(
              label: '최근 기상',
              value: recentWeather,
              items: const ['평년 수준', '고온', '저온', '강수 많음'],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  recentWeather = value;
                  prediction = null;
                });
              },
            ),
            LabeledDropdown(
              label: '재배 상태',
              value: cultivationStatus,
              items: const ['양호', '관수 필요', '병해 확인'],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  cultivationStatus = value;
                  prediction = null;
                });
              },
            ),
            PrimaryAction(
              label: predicting ? '예측 중' : '수확 예측 실행',
              onPressed: predicting ? null : _createPrediction,
            ),
            if (predicting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!predicting && currentPrediction == null)
              const NoticeBox(
                color: Color(0xffEEF6FF),
                text: '상품과 입력값을 확인한 뒤 수확 예측을 실행하세요.',
              ),
            if (!predicting && currentPrediction != null) ...[
              YieldChart(
                values: currentPrediction.trendValues,
                labels: currentPrediction.trendLabels,
              ),
              GridCards(
                children: [
                  MetricCard(
                    icon: Icons.calendar_month_outlined,
                    value: currentPrediction.period,
                    label: '예측 수확 날짜',
                  ),
                  MetricCard(
                    icon: Icons.scale_outlined,
                    value: currentPrediction.expectedYield,
                    label: '예상 수확량',
                  ),
                  MetricCard(
                    icon: Icons.shopping_bag_outlined,
                    value: currentPrediction.reservation,
                    label: '권장 예약량',
                  ),
                  MetricCard(
                    icon: Icons.paid_outlined,
                    value: currentPrediction.price,
                    label: '권장 판매가(kg 기준)',
                  ),
                ],
              ),
              DataTile(
                icon: Icons.verified_outlined,
                title: '신뢰도 ${currentPrediction.confidenceLabel}',
                subtitle: currentPrediction.warningMessage,
                badge: '',
                badgeColor: const Color(0xffDFF4E8),
              ),
              const NoticeBox(
                color: Color(0xffFFF1C7),
                text: '예측값은 참고용입니다. 실제 예약 슬롯은 점주가 아래 확정값을 조정한 뒤 열어야 합니다.',
              ),
              const SectionHeader(title: '슬롯 확정값'),
              Row(
                children: [
                  Expanded(
                    child: _DateSelectTile(
                      label: '수확 시작일',
                      value: confirmedStart,
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateSelectTile(
                      label: '수확 종료일',
                      value: confirmedEnd,
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              LabeledNumberStepper(
                label: '예약 가능 수량',
                value: confirmedReservableKg,
                min: 1,
                max: 100000,
                step: 10,
                suffixText: 'kg',
                onChanged: (value) =>
                    setState(() => confirmedReservableKg = value),
              ),
              LabeledNumberStepper(
                label: '확정 판매가',
                value: confirmedPrice,
                min: 1000,
                max: 300000,
                step: 1000,
                suffixText: '원/kg',
                onChanged: (value) => setState(() => confirmedPrice = value),
              ),
              LabeledBox(
                label: '고객 안내 문구',
                value: '',
                controller: noticeController,
                maxLength: 160,
              ),
              PrimaryAction(
                label: opening ? '처리 중' : '수확 슬롯 열기',
                onPressed: opening ? null : _openSlot,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _DateSelectTile extends StatelessWidget {
  const _DateSelectTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffDEE8DE)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xff6F7D68),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? '날짜 선택' : _dateLabel(value!),
                    style: const TextStyle(
                      color: Color(0xff102019),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_month_outlined, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _apiDate(DateTime date) => date.toIso8601String().substring(0, 10);

String _dateLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}
