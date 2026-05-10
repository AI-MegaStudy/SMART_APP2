import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/product_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProductEditPage extends StatefulWidget {
  final ProductRecord product;

  const ProductEditPage({super.key, required this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final formKey = GlobalKey<FormState>();
  final repository = ProductRepository();
  late String variety;
  late double packageUnitKg;
  late int price;
  late int stockBoxes;
  late String status;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final rawVariety = widget.product.variety.isEmpty
        ? ProductRecord.varietyFromProductName(widget.product.name)
        : widget.product.variety;
    variety = ProductRecord.appleVarieties.contains(rawVariety)
        ? rawVariety
        : ProductRecord.appleVarieties.first;
    packageUnitKg =
        ProductRecord.packageUnitKgOptions.contains(
          widget.product.packageUnitKg,
        )
        ? widget.product.packageUnitKg
        : 5;
    price = widget.product.price;
    stockBoxes = widget.product.stockKg;
    status = widget.product.status;
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      showOwnerSnack(context, '모든 항목을 입력한 뒤 수정하세요.');
      return;
    }
    await showConfirmAction(
      context: context,
      title: '상품 수정',
      message: '상품 정보를 수정할까요?',
      confirmLabel: '수정',
      onConfirm: () async {
        final productName = ProductRecord.productNameFromVariety(variety);
        final product = ProductRecord(
          productName,
          ProductRecord.packageLabel(packageUnitKg),
          price,
          stockBoxes,
          status,
          _statusColor(status),
          id: widget.product.id,
          farmId: widget.product.farmId,
          fruitType: '사과',
          variety: variety,
          description: widget.product.description,
          imageUrl: widget.product.imageUrl,
        );
        setState(() => isSaving = true);
        try {
          final saved = product.id == null
              ? product
              : await repository.updateProduct(product);
          if (!mounted) return;
          showOwnerSnack(context, '상품 정보를 수정했습니다.');
          Navigator.of(context).pop(saved);
        } on ApiException catch (error) {
          if (!mounted) return;
          showOwnerSnack(context, error.message);
        } catch (_) {
          if (!mounted) return;
          showOwnerSnack(context, '상품 수정에 실패했습니다.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '상품 수정',
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
              right: isSaving ? '저장 중' : '수정',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isSaving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
