import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/product_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProductAddPage extends StatefulWidget {
  final int farmId;

  const ProductAddPage({super.key, required this.farmId});

  @override
  State<ProductAddPage> createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  final formKey = GlobalKey<FormState>();
  final repository = ProductRepository();
  String variety = '';
  double packageUnitKg = 5;
  int price = 39000;
  int stockBoxes = 1;
  String status = '';
  bool isSaving = false;

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      showOwnerSnack(context, '모든 항목을 입력한 뒤 등록하세요.');
      return;
    }
    await showConfirmAction(
      context: context,
      title: '상품 등록',
      message: '새 상품을 등록할까요?',
      confirmLabel: '등록',
      onConfirm: () async {
        setState(() => isSaving = true);
        try {
          final productName = ProductRecord.productNameFromVariety(variety);
          final product = await repository.createProduct(
            farmId: widget.farmId,
            productName: productName,
            fruitType: '사과',
            variety: variety,
            packageUnitKg: packageUnitKg,
            basePrice: price,
            productStatus: ProductRecord.backendStatusFromLabel(status),
          );
          if (!mounted) return;
          showOwnerSnack(context, '상품을 등록했습니다.');
          Navigator.of(context).pop(product);
        } on ApiException catch (error) {
          if (!mounted) return;
          showOwnerSnack(context, error.message);
        } catch (_) {
          if (!mounted) return;
          showOwnerSnack(context, '상품 등록에 실패했습니다.');
        } finally {
          if (mounted) {
            setState(() => isSaving = false);
          }
        }
      },
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      '판매 중' => AppColors.mint,
      '준비 중' => AppColors.yellow,
      _ => const Color(0xffFFE1DD),
    };
  }

  ProductRecord _offlineProduct() {
    final productName = ProductRecord.productNameFromVariety(variety);
    return ProductRecord(
      productName,
      ProductRecord.packageLabel(packageUnitKg),
      price,
      stockBoxes,
      status,
      _statusColor(status),
      farmId: widget.farmId,
      fruitType: '사과',
      variety: variety,
    );
  }

  Future<void> _saveOfflineForDemo() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      showOwnerSnack(context, '모든 항목을 입력한 뒤 등록하세요.');
      return;
    }
    await showConfirmAction(
      context: context,
      title: '상품 등록',
      message: '서버 연결 없이 화면에만 추가할까요?',
      confirmLabel: '추가',
      onConfirm: () {
        final product = _offlineProduct();
        showOwnerSnack(context, '화면에 상품을 추가했습니다.');
        Navigator.of(context).pop(product);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '상품 추가',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: [
            LabeledDropdown(
              label: '사과 품종',
              value: variety,
              items: ProductRecord.appleVarieties,
              onChanged: (value) {
                if (value != null) {
                  setState(() => variety = value);
                }
              },
            ),
            LabeledDropdown(
              label: '포장 단위',
              value: ProductRecord.packageLabel(packageUnitKg),
              items: [
                for (final value in ProductRecord.packageUnitKgOptions)
                  ProductRecord.packageLabel(value),
              ],
              onChanged: (value) {
                if (value == null) return;
                final parsed = value.replaceAll(RegExp(r'[^0-9.]'), '');
                setState(() => packageUnitKg = double.tryParse(parsed) ?? 5);
              },
            ),
            LabeledNumberStepper(
              label: '기본 판매가',
              value: price,
              min: 1000,
              max: 300000,
              step: 1000,
              suffixText: '원',
              onChanged: (value) => setState(() => price = value),
            ),
            LabeledNumberStepper(
              label: '표시 수량',
              value: stockBoxes,
              min: 0,
              max: 999,
              step: 1,
              suffixText: '박스',
              onChanged: (value) => setState(() => stockBoxes = value),
            ),
            const NoticeBox(
              color: AppColors.yellow,
              text: '상품 수량은 현재 화면 표시값입니다. 실제 예약 가능 수량은 수확 슬롯에서 관리합니다.',
            ),
            LabeledDropdown(
              label: '판매 상태',
              value: status,
              items: const ['판매 중', '준비 중', '판매 중지'],
              onChanged: (value) {
                if (value != null) {
                  setState(() => status = value);
                }
              },
            ),
            DualActionBar(
              left: '취소',
              right: isSaving ? '저장 중' : '등록',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isSaving ? () {} : _save,
            ),
            TextButton(
              onPressed: isSaving ? null : _saveOfflineForDemo,
              child: const Text('서버 없이 화면에만 추가'),
            ),
          ],
        ),
      ),
    );
  }
}
