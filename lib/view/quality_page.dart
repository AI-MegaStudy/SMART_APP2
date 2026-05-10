import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class QualityPage extends StatefulWidget {
  const QualityPage({super.key});

  @override
  State<QualityPage> createState() => _QualityPageState();
}

class _QualityPageState extends State<QualityPage> {
  final imagePicker = ImagePicker();
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  Offset inspectionAnchor = const Offset(0.5, 0.72);

  @override
  void initState() {
    super.initState();
    _retrieveLostImage();
  }

  Future<void> _openGallery() async {
    try {
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked == null) {
        return;
      }
      await _setSelectedImage(picked);
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      showOwnerSnack(context, _galleryErrorMessage(error));
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      showOwnerSnack(context, '갤러리 플러그인이 아직 연결되지 않았습니다. 앱을 완전히 다시 실행하세요.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      showOwnerSnack(context, '갤러리를 여는 중 문제가 발생했습니다.');
    }
  }

  Future<void> _retrieveLostImage() async {
    try {
      final response = await imagePicker.retrieveLostData();
      if (response.isEmpty) {
        return;
      }
      if (response.exception != null) {
        if (mounted) {
          showOwnerSnack(context, _galleryErrorMessage(response.exception!));
        }
        return;
      }

      final files = response.files;
      final picked = files?.isNotEmpty == true ? files!.last : response.file;
      if (picked != null) {
        await _setSelectedImage(picked);
      }
    } catch (_) {
      // retrieveLostData is Android-only in practice; ignore unsupported paths.
    }
  }

  Future<void> _setSelectedImage(XFile picked) async {
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    setState(() {
      selectedImageBytes = bytes;
      selectedImageName = picked.name.isEmpty ? '선택한 이미지' : picked.name;
      inspectionAnchor = const Offset(0.5, 0.72);
    });
  }

  String _galleryErrorMessage(PlatformException error) {
    if (error.code == 'photo_access_denied' ||
        error.code == 'camera_access_denied') {
      return '사진 접근 권한을 허용한 뒤 다시 시도하세요.';
    }
    if (error.code == 'already_active') {
      return '갤러리가 이미 열려 있습니다.';
    }
    final detail = error.message ?? error.details?.toString();
    if (detail == null || detail.trim().isEmpty) {
      return '갤러리를 여는 중 문제가 발생했습니다. (${error.code})';
    }
    return '갤러리를 여는 중 문제가 발생했습니다. (${error.code}: $detail)';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = selectedImageBytes != null;

    return Scaffold(
      body: AppScaffold(
        title: '신선도 검사',
        leading: ActionChipIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: ActionChipIcon(
          icon: Icons.image_outlined,
          onPressed: _openGallery,
        ),
        children: [
          CameraPreviewCard(
            icon: Icons.image_search_outlined,
            label: hasImage ? selectedImageName : null,
            hasImage: hasImage,
            imageBytes: selectedImageBytes,
            inspectionAnchor: inspectionAnchor,
            onInspectionAnchorChanged: (anchor) {
              setState(() => inspectionAnchor = anchor);
            },
          ),
          const NoticeBox(
            color: AppColors.blue,
            text: '판별 결과는 선별 보조 자료입니다. 최종 등급과 출고 여부는 점주가 확정합니다.',
          ),
          const GridCards(
            children: [
              MetricCard(
                icon: Icons.workspace_premium_outlined,
                value: 'A',
                label: '추천 등급',
              ),
              MetricCard(
                icon: Icons.monitor_heart_outlined,
                value: '91점',
                label: '신선도',
              ),
            ],
          ),
          const DataTile(
            icon: Icons.check_circle_outline,
            title: '멍 가능성 낮음',
            subtitle: '색상과 둥근 정도가 출고 기준을 충족합니다.',
            badge: '통과',
            badgeColor: AppColors.mint,
          ),
        ],
      ),
    );
  }
}
