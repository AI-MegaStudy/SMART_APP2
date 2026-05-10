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
  final packageController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final repository = ProductRepository();
  String productName = '';
  String status = '';
  bool isSaving = false;

  @override
  void dispose() {
    packageController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

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
          final product = await repository.createProduct(
            farmId: widget.farmId,
            productName: productName,
            fruitType: _fruitType(productName),
            variety: _variety(productName),
            packageUnitKg: double.parse(packageController.text),
            basePrice: int.parse(priceController.text),
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

  String _fruitType(String productName) {
    if (productName.contains('사과')) return '사과';
    return productName;
  }

  String _variety(String productName) {
    return productName.replaceAll('사과', '').trim().isEmpty
        ? productName
        : productName.replaceAll('사과', '').trim();
  }

  Color _statusColor(String status) {
    return switch (status) {
      '판매 중' => AppColors.mint,
      '준비 중' => AppColors.yellow,
      _ => const Color(0xffFFE1DD),
    };
  }

  ProductRecord _offlineProduct() {
    return ProductRecord(
      productName,
      '${packageController.text}kg 박스',
      int.parse(priceController.text),
      int.parse(stockController.text),
      status,
      _statusColor(status),
      farmId: widget.farmId,
      fruitType: _fruitType(productName),
      variety: _variety(productName),
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
              label: '상품명',
              value: productName,
              items: const ['양광 사과', '부사 사과'],
              onChanged: (value) {
                if (value != null) {
                  setState(() => productName = value);
                }
              },
            ),
            LabeledField(
              label: '포장 단위',
              value: '',
              controller: packageController,
              hintText: '포장 단위',
              keyboardType: TextInputType.number,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: (text) {
                final required = requiredValidator('포장 단위', text);
                if (required != null) return required;
                return RegExp(r'^\d+$').hasMatch(text!.trim())
                    ? null
                    : '포장 단위에는 숫자만 입력하세요.';
              },
              suffixText: 'kg 박스',
            ),
            LabeledField(
              label: '기본 판매가',
              value: '',
              controller: priceController,
              hintText: '기본 판매가',
              keyboardType: TextInputType.number,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: (text) {
                final required = requiredValidator('기본 판매가', text);
                if (required != null) return required;
                return RegExp(r'^\d+$').hasMatch(text!.trim())
                    ? null
                    : '기본 판매가에는 숫자만 입력하세요.';
              },
              suffixText: '원',
            ),
            LabeledField(
              label: '상품 수량',
              value: '',
              controller: stockController,
              hintText: '상품 수량',
              keyboardType: TextInputType.number,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: (text) {
                final required = requiredValidator('상품 수량', text);
                if (required != null) return required;
                return RegExp(r'^\d+$').hasMatch(text!.trim())
                    ? null
                    : '상품 수량에는 숫자만 입력하세요.';
              },
              suffixText: '박스',
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
