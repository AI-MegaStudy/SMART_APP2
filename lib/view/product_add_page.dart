import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/product_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProductAddPage extends StatefulWidget {
  final int farmId;
  final bool demoPreset;
  final String? demoImageAsset;

  const ProductAddPage({
    super.key,
    required this.farmId,
    this.demoPreset = false,
    this.demoImageAsset,
  });

  @override
  State<ProductAddPage> createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  final formKey = GlobalKey<FormState>();
  final repository = ProductRepository();
  final imagePicker = ImagePicker();
  final descriptionController = TextEditingController();
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  String variety = '';
  double packageUnitKg = 5;
  int price = 39000;
  int stockBoxes = 1;
  String status = '';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.demoPreset) {
      variety = '양광';
      packageUnitKg = 5;
      price = 41000;
      stockBoxes = 24;
      status = '판매 중';
      descriptionController.text = '당일 선별한 데모 등록용 양광 사과입니다.';
      _loadDemoImage();
    }
  }

  Future<void> _loadDemoImage() async {
    final asset = widget.demoImageAsset;
    if (asset == null || asset.isEmpty) return;
    try {
      final data = await rootBundle.load(asset);
      if (!mounted) return;
      setState(() {
        selectedImageBytes = data.buffer.asUint8List();
        selectedImageName = asset.split('/').last;
      });
    } catch (_) {
      // 데모 이미지는 선택 보조용이므로 실패해도 일반 등록 흐름은 유지한다.
    }
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
          final productName = ProductRecord.productNameFromVariety(variety);
          var product = await repository.createProduct(
            farmId: widget.farmId,
            productName: productName,
            fruitType: '사과',
            variety: variety,
            packageUnitKg: packageUnitKg,
            basePrice: price,
            productStatus: ProductRecord.backendStatusFromLabel(status),
            productDescription: descriptionController.text.trim(),
          );
          if (selectedImageBytes != null &&
              selectedImageName != null &&
              product.id != null) {
            product = await repository.uploadProductImage(
              productId: product.id!,
              fileName: selectedImageName!,
              fileBytes: selectedImageBytes!,
            );
          }
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

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        selectedImageBytes = bytes;
        selectedImageName = picked.name.isEmpty ? 'product.jpg' : picked.name;
      });
    } catch (_) {
      if (!mounted) return;
      showOwnerSnack(context, '이미지를 선택하지 못했습니다.');
    }
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
              key: DemoTargetKeys.productAddVariety,
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
              key: DemoTargetKeys.productAddPackage,
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
            CameraPreviewCard(
              key: DemoTargetKeys.productAddImage,
              icon: Icons.image_outlined,
              label: selectedImageName ?? '상품 대표 이미지 선택',
              hasImage: selectedImageBytes != null,
              imageBytes: selectedImageBytes,
              onTap: _pickImage,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(selectedImageBytes == null ? '이미지 선택' : '이미지 변경'),
              ),
            ),
            LabeledNumberStepper(
              key: DemoTargetKeys.productAddPrice,
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
            LabeledBox(
              label: '상품 소개',
              value: '',
              controller: descriptionController,
              hintText: '예: 당도와 산미 균형이 좋은 당일 선별 사과입니다.',
              maxLength: 160,
              required: false,
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
              rightKey: DemoTargetKeys.productAddSave,
              left: '취소',
              right: isSaving ? '저장 중' : '등록',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isSaving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
