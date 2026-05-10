import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/view/procurement_status_page.dart';
import 'package:smart_app/view/shipment_status_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ShipmentPage extends StatefulWidget {
  const ShipmentPage({super.key});

  @override
  State<ShipmentPage> createState() => _ShipmentPageState();
}

class _ShipmentPageState extends State<ShipmentPage> {
  final formKey = GlobalKey<FormState>();
  final invoiceController = TextEditingController();
  final boxesController = TextEditingController();
  final weightController = TextEditingController();
  String selectedProduct = '';
  String courier = '';
  final registeredShipmentProducts = <String>{};

  @override
  void dispose() {
    invoiceController.dispose();
    boxesController.dispose();
    weightController.dispose();
    super.dispose();
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
    final product = _ShipmentProduct.approvedItems.firstWhere(
      (item) => item.name == value,
    );
    setState(() {
      selectedProduct = product.name;
      boxesController.text = product.boxes;
      weightController.text = product.weight;
    });
  }

  void _registerShipment() {
    if (!(formKey.currentState?.validate() ?? false)) {
      showOwnerSnack(context, '모든 정보를 입력해야 등록이 가능합니다.');
      return;
    }

    showConfirmAction(
      context: context,
      title: '등록',
      message: '배송 정보를 등록할까요?',
      confirmLabel: '등록',
      onConfirm: () {
        final registeredProduct = selectedProduct;
        shipmentStatusRecords.add(
          ShipmentRecord(
            registeredProduct,
            '$courier · ${invoiceController.text}',
            '배송 대기',
            AppColors.yellow,
          ),
        );
        setState(() {
          registeredShipmentProducts.add(registeredProduct);
          selectedProduct = '';
          courier = '';
          invoiceController.clear();
          boxesController.clear();
          weightController.clear();
        });
        showOwnerSnack(context, '$registeredProduct 배송 정보를 등록했습니다.');
      },
    );
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
            icon: Icons.qr_code_scanner,
            onPressed: () => showOwnerSnack(context, '포장 바코드 스캔을 준비합니다.'),
          ),
          children: [
            LabeledDropdown(
              label: '발주 승인 상품',
              value: selectedProduct,
              items: [
                for (final product in _ShipmentProduct.approvedItems)
                  if (!registeredShipmentProducts.contains(product.name))
                    product.name,
              ],
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
              left: '취소',
              right: '등록',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: _registerShipment,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentProduct {
  final String name;
  final String boxes;
  final String weight;

  const _ShipmentProduct(this.name, this.boxes, this.weight);

  static List<_ShipmentProduct> get approvedItems {
    final approved = procurementStatusRecords.where(
      (record) => record.status == '승인',
    );
    return [
      for (final record in approved)
        _ShipmentProduct.fromProcurement(record.subtitle),
    ];
  }

  factory _ShipmentProduct.fromProcurement(String text) {
    final parts = text.split(' · ');
    final namePartCount = parts.length > 2 && parts[2].contains('박스') ? 3 : 2;
    final name = parts.take(namePartCount).join(' · ');
    final boxMatch = RegExp(r'(\d+)박스').firstMatch(text);
    final weightMatch = RegExp(r'(\d+)kg').firstMatch(text);
    final boxCount = boxMatch?.group(1) ?? '1';
    final weight = weightMatch?.group(1) ?? '5';
    return _ShipmentProduct(name, boxCount, weight);
  }
}
