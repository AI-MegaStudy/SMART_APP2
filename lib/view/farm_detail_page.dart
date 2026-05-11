import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kpostal_plus/kpostal_plus.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/product_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class FarmDetailPage extends StatefulWidget {
  const FarmDetailPage({super.key});

  @override
  State<FarmDetailPage> createState() => _FarmDetailPageState();
}

class _FarmDetailPageState extends State<FarmDetailPage> {
  final formKey = GlobalKey<FormState>();
  final farmNameController = TextEditingController();
  final addressController = TextEditingController();
  final introController = TextEditingController();
  final shippingPolicyController = TextEditingController();
  final returnPolicyController = TextEditingController();
  final repository = ProductRepository();
  final imagePicker = ImagePicker();
  OwnerFarmRecord? farm;
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  bool isLoading = false;
  bool isSaving = false;
  String? loadError;
  static const fallbackAddresses = [
    '충북 충주시 산척면 과수원길 24',
    '충북 충주시 주덕읍 냇내로 18',
    '충북 충주시 동량면 사과밭길 7',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    farmNameController.dispose();
    addressController.dispose();
    introController.dispose();
    shippingPolicyController.dispose();
    returnPolicyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final farms = await repository.fetchOwnerFarms();
      if (!mounted) return;
      if (farms.isEmpty) {
        setState(() => loadError = '등록된 농장 정보가 없습니다.');
        return;
      }
      final loaded = farms.first;
      setState(() {
        farm = loaded;
        farmNameController.text = loaded.farmName;
        addressController.text = loaded.farmAddress;
        introController.text = loaded.farmDescription ?? '';
        shippingPolicyController.text = loaded.deliveryPolicy ?? '';
        returnPolicyController.text = loaded.returnPolicy ?? '';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => loadError = '서버 연결을 확인해주세요.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (farm == null) {
      showOwnerSnack(context, '저장할 농장 ID가 없습니다.');
      return;
    }
    await showConfirmAction(
      context: context,
      title: '농장 정보 저장',
      message: '입력한 농장 정보로 저장할까요?',
      onConfirm: () async {
        setState(() => isSaving = true);
        try {
          var farmImageUrl = farm!.farmImageUrl;
          if (selectedImageBytes != null && selectedImageName != null) {
            final uploaded = await repository.uploadFarmImage(
              farmId: farm!.farmId,
              fileName: selectedImageName!,
              fileBytes: selectedImageBytes!,
            );
            farmImageUrl = uploaded.farmImageUrl;
          }
          final saved = await repository.updateFarm(
            OwnerFarmRecord(
              farmId: farm!.farmId,
              farmName: farmNameController.text.trim(),
              farmRegion: farm!.farmRegion,
              farmAddress: addressController.text.trim(),
              farmImageUrl: farmImageUrl,
              farmDescription: introController.text.trim(),
              deliveryPolicy: shippingPolicyController.text.trim(),
              returnPolicy: returnPolicyController.text.trim(),
            ),
          );
          if (!mounted) return;
          setState(() {
            farm = saved;
            selectedImageBytes = null;
            selectedImageName = null;
          });
          await showInfoAction(
            context: context,
            title: '농장 정보 저장',
            message: '저장이 완료되었습니다.',
            onConfirm: () => Navigator.of(context).pop(),
          );
        } on ApiException catch (error) {
          if (!mounted) return;
          showOwnerSnack(context, error.message);
        } catch (_) {
          if (!mounted) return;
          showOwnerSnack(context, '농장 정보 저장에 실패했습니다.');
        } finally {
          if (mounted) {
            setState(() => isSaving = false);
          }
        }
      },
    );
  }

  Future<void> _searchAddress() async {
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      final selected = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              const SectionHeader(title: '주소 검색 결과'),
              for (final address in fallbackAddresses)
                ListTile(
                  title: Text(address),
                  leading: const Icon(Icons.location_on_outlined),
                  onTap: () => Navigator.of(context).pop(address),
                ),
            ],
          ),
        ),
      );
      if (selected != null) setState(() => addressController.text = selected);
      return;
    }

    final result = await Navigator.of(context).push<Kpostal>(
      MaterialPageRoute(
        builder: (_) => KpostalPlusView(
          title: '주소 검색',
          appBarColor: AppColors.green,
          titleColor: Colors.white,
        ),
      ),
    );
    if (result == null) return;
    final selected = result.userSelectedAddress.isNotEmpty
        ? result.userSelectedAddress
        : result.address;
    setState(() => addressController.text = selected);
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
        selectedImageName = picked.name.isEmpty ? 'farm.jpg' : picked.name;
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
          title: '농장 정보 수정',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: [
            if (isLoading) const LinearProgressIndicator(minHeight: 3),
            if (loadError != null)
              NoticeBox(color: AppColors.yellow, text: loadError!),
            LabeledField(
              key: DemoTargetKeys.farmDetailName,
              label: '농장명',
              value: '',
              controller: farmNameController,
              hintText: '농장명',
            ),
            LabeledField(
              label: '주소',
              value: '',
              controller: addressController,
              hintText: '주소',
              readOnly: true,
              validator: (value) => requiredValidator('주소', value),
            ),
            FilledButton.tonalIcon(
              onPressed: _searchAddress,
              icon: const Icon(Icons.search),
              label: const Text('주소 검색'),
            ),
            CameraPreviewCard(
              key: DemoTargetKeys.farmDetailImage,
              icon: Icons.photo_camera_back_outlined,
              label:
                  selectedImageName ??
                  (farm?.farmImageUrl?.isNotEmpty == true
                      ? '등록된 농장 이미지'
                      : '농장 대표 이미지 선택'),
              hasImage:
                  selectedImageBytes != null ||
                  farm?.farmImageUrl?.isNotEmpty == true,
              imageBytes: selectedImageBytes,
              imageUrl: selectedImageBytes == null ? farm?.farmImageUrl : null,
              onTap: _pickImage,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  farm?.farmImageUrl?.isNotEmpty == true ||
                          selectedImageBytes != null
                      ? '이미지 변경'
                      : '이미지 선택',
                ),
              ),
            ),
            LabeledBox(
              label: '농장 소개',
              value: '',
              controller: introController,
              required: false,
              showCounter: true,
            ),
            LabeledBox(
              label: '배송 정책',
              value: '',
              controller: shippingPolicyController,
              required: false,
              showCounter: true,
            ),
            LabeledBox(
              label: '반품 정책',
              value: '',
              controller: returnPolicyController,
              required: false,
              showCounter: true,
            ),
            DualActionBar(
              left: '취소',
              right: isSaving ? '저장 중' : '저장',
              rightKey: DemoTargetKeys.farmDetailSave,
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isSaving ? () {} : _save,
            ),
          ],
        ),
      ),
    );
  }
}
