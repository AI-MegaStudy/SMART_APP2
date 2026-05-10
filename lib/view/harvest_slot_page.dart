import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/model/harvest_slot_record.dart';
import 'package:smart_app/repositories/harvest_repository.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class HarvestSlotPage extends StatefulWidget {
  const HarvestSlotPage({super.key});

  @override
  State<HarvestSlotPage> createState() => _HarvestSlotPageState();
}

class _HarvestSlotPageState extends State<HarvestSlotPage> {
  final repository = HarvestRepository();
  var options = <HarvestProductOption>[];
  HarvestProductOption? selectedOption;
  HarvestPredictionRecord? prediction;
  bool loading = true;
  bool predicting = false;
  bool opening = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOptions();
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
      loading = false;
      setState(() {});
      if (selectedOption != null) {
        await _createPrediction();
      }
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
      final created = await repository.createPrediction(option);
      if (!mounted) return;
      setState(() => prediction = created);
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

    showConfirmAction(
      context: context,
      title: '수확 슬롯 열기',
      message: '${option.product.name} 예약 가능 수량을 열까요?',
      confirmLabel: '열기',
      onConfirm: () async {
        setState(() => opening = true);
        try {
          await repository.createOpenSlot(
            option: option,
            prediction: currentPrediction,
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
                setState(() => selectedOption = next);
                _createPrediction();
              },
            ),
            const YieldChart(),
            if (predicting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!predicting && currentPrediction != null) ...[
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
