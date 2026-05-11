import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ShipmentPage extends StatefulWidget {
  final bool demoAutofill;

  const ShipmentPage({super.key, this.demoAutofill = false});

  @override
  State<ShipmentPage> createState() => _ShipmentPageState();
}

class _ShipmentPageState extends State<ShipmentPage> {
  final formKey = GlobalKey<FormState>();
  final invoiceController = TextEditingController();
  final boxesController = TextEditingController();
  final weightController = TextEditingController();
  final repository = OwnerWorkflowRepository();
  List<OwnerProcurementRequestRecord> shippableProcurements = const [];
  String selectedProduct = '';
  String courier = '';
  bool isLoading = false;
  bool isSubmitting = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadShippableProcurements();
  }

  @override
  void dispose() {
    invoiceController.dispose();
    boxesController.dispose();
    weightController.dispose();
    super.dispose();
  }

  Future<void> _loadShippableProcurements() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final loaded = await repository.fetchShippableProcurements();
      if (!mounted) return;
      setState(() => shippableProcurements = loaded);
      if (widget.demoAutofill) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (shippableProcurements.isNotEmpty && selectedProduct.isEmpty) {
            _selectProduct(shippableProcurements.first.title);
          }
          _scanPackingCode();
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loadError = '배송 등록 가능한 발주를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _selectProduct(String value) {
    if (value.isEmpty) {
      setState(() {
        selectedProduct = '';
        boxesController.clear();
        weightController.clear();
      });
      return;
    }
    final request = shippableProcurements.firstWhere(
      (item) => item.title == value,
    );
    final item = request.items.isEmpty ? null : request.items.first;
    setState(() {
      selectedProduct = request.title;
      boxesController.text = '${item?.requestedPackageCount ?? 1}';
      weightController.text = '${item?.requestedKg.round() ?? 0}';
    });
  }

  Future<void> _registerShipment() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      showOwnerSnack(context, '모든 정보를 입력해야 등록이 가능합니다.');
      return;
    }
    final selected = shippableProcurements.where(
      (item) => item.title == selectedProduct,
    );
    if (selected.isEmpty) {
      showOwnerSnack(context, '배송 등록할 발주를 선택하세요.');
      return;
    }

    showConfirmAction(
      context: context,
      title: '등록',
      message: '배송 정보를 등록할까요?',
      confirmLabel: '등록',
      onConfirm: () async {
        setState(() => isSubmitting = true);
        final request = selected.first;
        final saved = await repository.createShipment(
          request: request,
          carrierName: courier,
          trackingNo: invoiceController.text.trim(),
          shippedPackageCount: int.parse(boxesController.text.trim()),
          shippedKg: double.parse(weightController.text.trim()),
        );
        if (!mounted) return;
        setState(() {
          isSubmitting = false;
          selectedProduct = '';
          courier = '';
          invoiceController.clear();
          boxesController.clear();
          weightController.clear();
        });
        if (saved) {
          await _loadShippableProcurements();
          if (!mounted) return;
          showOwnerSnack(context, '${request.title} 배송 정보를 등록했습니다.');
        } else {
          showOwnerSnack(context, '배송 등록 조건을 다시 확인하세요.');
        }
      },
    );
  }

  void _scanPackingCode() {
    final now = DateTime.now();
    final generatedNo =
        '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    setState(() {
      courier = courier.isEmpty ? 'CJ대한통운' : courier;
      invoiceController.text = generatedNo;
    });
    showOwnerSnack(context, '포장 코드에서 송장 정보를 불러왔습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '배송 관리',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailing: ActionChipIcon(
            key: DemoTargetKeys.shipmentScan,
            icon: Icons.qr_code_scanner,
            onPressed: _scanPackingCode,
          ),
          children: [
            if (isLoading) const LinearProgressIndicator(minHeight: 3),
            if (loadError != null)
              NoticeBox(color: AppColors.yellow, text: loadError!),
            if (!isLoading && shippableProcurements.isEmpty)
              const NoticeBox(
                color: AppColors.yellow,
                text: '배송 등록 가능한 승인 발주가 없습니다. 발주 승인 후 배송 등록이 가능합니다.',
              ),
            LabeledDropdown(
              key: DemoTargetKeys.shipmentProduct,
              label: '발주 승인 상품',
              value: selectedProduct,
              items: [for (final item in shippableProcurements) item.title],
              onChanged: (value) {
                if (value != null) {
                  _selectProduct(value);
                }
              },
            ),
            LabeledDropdown(
              label: '택배사',
              value: courier,
              items: const ['CJ대한통운', '롯데택배', '한진택배', '우체국택배', '로젠택배'],
              onChanged: (value) {
                if (value != null) {
                  setState(() => courier = value);
                }
              },
            ),
            LabeledField(
              key: DemoTargetKeys.shipmentInvoice,
              label: '송장번호',
              value: '',
              controller: invoiceController,
              hintText: '송장번호',
              keyboardType: TextInputType.number,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: invoiceNumberValidator,
            ),
            LabeledField(
              label: '발송 중량',
              value: '',
              controller: weightController,
              keyboardType: TextInputType.number,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: (text) {
                final required = requiredValidator('발송 중량', text);
                if (required != null) return required;
                return RegExp(r'^\d+$').hasMatch(text!.trim())
                    ? null
                    : '발송 중량에는 숫자만 입력하세요.';
              },
              suffixText: 'kg',
            ),
            LabeledField(
              label: '발송 박스 수',
              value: '',
              controller: boxesController,
              keyboardType: TextInputType.number,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: (text) {
                final required = requiredValidator('발송 박스 수', text);
                if (required != null) return required;
                return RegExp(r'^\d+$').hasMatch(text!.trim())
                    ? null
                    : '발송 박스 수에는 숫자만 입력하세요.';
              },
              suffixText: '박스',
            ),
            DualActionBar(
              rightKey: DemoTargetKeys.shipmentRegister,
              left: '취소',
              right: isSubmitting ? '등록 중' : '등록',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isSubmitting ? null : _registerShipment,
            ),
          ],
        ),
      ),
    );
  }
}
