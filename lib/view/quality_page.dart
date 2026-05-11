import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/quality_record.dart';
import 'package:smart_app/repositories/quality_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class QualityPage extends StatefulWidget {
  final bool demoAutoImage;
  final bool demoAutoAnalyze;

  const QualityPage({
    super.key,
    this.demoAutoImage = false,
    this.demoAutoAnalyze = false,
  });

  @override
  State<QualityPage> createState() => _QualityPageState();
}

class _QualityPageState extends State<QualityPage> {
  final imagePicker = ImagePicker();
  final repository = QualityRepository();
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  List<QualityTargetRecord> targets = const [];
  QualityTargetRecord? selectedTarget;
  QualityAnalysisRecord? analysis;
  String ownerGrade = 'A';
  String ownerDecision = 'PASS';
  Offset inspectionAnchor = const Offset(0.5, 0.72);
  bool isLoading = false;
  bool isAnalyzing = false;
  bool isSaving = false;
  bool demoAnalyzeScheduled = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    _loadTargets();
    _retrieveLostImage();
  }

  Future<void> _loadTargets() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      final loaded = await repository.fetchInspectionTargets();
      if (!mounted) return;
      setState(() {
        targets = loaded;
        selectedTarget = loaded.isEmpty ? null : loaded.first;
      });
      if (widget.demoAutoImage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && selectedImageBytes == null) _applyDemoImage();
        });
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => loadError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => loadError = '신선도 검사 대상 발주를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
    } on PlatformException {
      if (!mounted) {
        return;
      }
      await _applyDemoImage();
      if (!mounted) return;
      showOwnerSnack(context, '샘플 이미지를 불러왔습니다.');
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      await _applyDemoImage();
      if (!mounted) return;
      showOwnerSnack(context, '샘플 이미지를 불러왔습니다.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _applyDemoImage();
      if (!mounted) return;
      showOwnerSnack(context, '샘플 이미지를 불러왔습니다.');
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
      analysis = null;
    });
  }

  Future<void> _applyDemoImage() async {
    final asset = selectedTarget?.productName.contains('부사') == true
        ? 'assets/images/owner_demo/demo_fuji_product.png'
        : 'assets/images/owner_demo/demo_yanggwang_product.png';
    final data = await rootBundle.load(asset);
    if (!mounted) return;
    setState(() {
      selectedImageBytes = data.buffer.asUint8List();
      selectedImageName = asset.split('/').last;
      inspectionAnchor = const Offset(0.5, 0.72);
      analysis = null;
    });
    _scheduleDemoAnalyze();
  }

  void _scheduleDemoAnalyze() {
    if (!widget.demoAutoAnalyze || demoAnalyzeScheduled) return;
    demoAnalyzeScheduled = true;
    Future<void>.delayed(const Duration(milliseconds: 9300), () {
      if (!mounted || selectedImageBytes == null || analysis != null) return;
      _analyze();
    });
  }

  Future<void> _analyze() async {
    final target = selectedTarget;
    final bytes = selectedImageBytes;
    final fileName = selectedImageName;
    if (target == null) {
      showOwnerSnack(context, '검사할 발주 품목을 선택하세요.');
      return;
    }
    if (bytes == null || fileName == null) {
      showOwnerSnack(context, '검사할 이미지를 선택하세요.');
      return;
    }
    setState(() => isAnalyzing = true);
    try {
      final uploaded = await repository.uploadImage(
        fileName: fileName,
        fileBytes: bytes,
      );
      final result = await repository.analyzeImage(
        procurementItemId: target.procurementItemId,
        imageUrl: uploaded.imageUrl,
        fileName: fileName,
        fileBytes: bytes,
      );
      if (!mounted) return;
      setState(() {
        analysis = result;
        ownerGrade = result.modelGrade;
        ownerDecision = result.modelDecision == 'PASS' ? 'PASS' : 'HOLD';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _applyLocalAnalysis(fileName, bytes.length);
      showOwnerSnack(context, '${error.message} 선택 이미지 기준 보조 판정을 표시합니다.');
    } catch (_) {
      if (!mounted) return;
      _applyLocalAnalysis(fileName, bytes.length);
      showOwnerSnack(context, '선택 이미지 기준 보조 판정을 표시합니다.');
    } finally {
      if (mounted) setState(() => isAnalyzing = false);
    }
  }

  void _applyLocalAnalysis(String fileName, int byteLength) {
    final fallback = QualityAnalysisRecord.localEstimate(
      imageName: fileName,
      byteLength: byteLength,
    );
    setState(() {
      analysis = fallback;
      ownerGrade = fallback.modelGrade;
      ownerDecision = fallback.modelDecision == 'PASS' ? 'PASS' : 'HOLD';
    });
  }

  Future<void> _saveInspection() async {
    final target = selectedTarget;
    final result = analysis;
    if (target == null || result == null) {
      showOwnerSnack(context, '분석 완료 후 저장할 수 있습니다.');
      return;
    }
    setState(() => isSaving = true);
    try {
      await repository.saveInspection(
        procurementItemId: target.procurementItemId,
        imageUrl: result.imageUrl.isNotEmpty ? result.imageUrl : '',
        ownerConfirmedGrade: ownerGrade,
        ownerDecision: ownerDecision,
        analysis: result,
      );
      if (!mounted) return;
      showOwnerSnack(context, '신선도 검사 결과를 저장했습니다.');
    } on ApiException catch (error) {
      if (!mounted) return;
      showOwnerSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showOwnerSnack(context, '신선도 검사 결과 저장에 실패했습니다.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
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
          if (isLoading) const LinearProgressIndicator(minHeight: 3),
          if (loadError != null)
            NoticeBox(color: AppColors.yellow, text: loadError!),
          if (!isLoading && targets.isEmpty)
            const NoticeBox(
              color: AppColors.yellow,
              text: '승인된 발주 품목이 없어 신선도 검사를 저장할 수 없습니다.',
            ),
          LabeledDropdown(
            key: DemoTargetKeys.qualityTarget,
            label: '검사 대상 발주 품목',
            value: selectedTarget?.title ?? '',
            items: [for (final target in targets) target.title],
            onChanged: (value) {
              final selected = targets.where((item) => item.title == value);
              setState(() {
                selectedTarget = selected.isEmpty ? null : selected.first;
                analysis = null;
              });
            },
          ),
          CameraPreviewCard(
            key: DemoTargetKeys.qualityImage,
            icon: Icons.image_search_outlined,
            label: null,
            hasImage: hasImage,
            imageBytes: selectedImageBytes,
            inspectionAnchor: inspectionAnchor,
            onTap: _openGallery,
            onInspectionAnchorChanged: (anchor) {
              setState(() => inspectionAnchor = anchor);
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openGallery,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(hasImage ? '이미지 다시 선택' : '갤러리에서 선택'),
            ),
          ),
          const NoticeBox(
            color: AppColors.blue,
            text: '판별 결과는 선별 보조 자료입니다. 최종 등급과 출고 여부는 점주가 확정합니다.',
          ),
          GridCards(
            key: DemoTargetKeys.qualityResult,
            children: [
              MetricCard(
                icon: Icons.workspace_premium_outlined,
                value: analysis?.modelGrade ?? '-',
                label: '추천 등급',
              ),
              MetricCard(
                icon: Icons.monitor_heart_outlined,
                value: analysis?.freshnessLabel ?? '-',
                label: '신선도',
              ),
              MetricCard(
                icon: Icons.palette_outlined,
                value: analysis?.colorLabel ?? '-',
                label: '색상 점수',
              ),
              MetricCard(
                icon: Icons.circle_outlined,
                value: analysis?.roundnessLabel ?? '-',
                label: '형태 점수',
              ),
            ],
          ),
          DataTile(
            key: DemoTargetKeys.qualityDecision,
            icon: Icons.check_circle_outline,
            title: analysis?.bruiseLabel ?? '분석 대기',
            subtitle: analysis == null
                ? selectedTarget?.subtitle ?? '검사 대상과 이미지를 선택하세요.'
                : '${selectedTarget?.subtitle ?? '검사 대상'} · 멍 확률 ${analysis!.bruiseProbabilityLabel}',
            badge: analysis?.decisionLabel ?? '대기',
            badgeColor: AppColors.mint,
          ),
          LabeledDropdown(
            key: DemoTargetKeys.qualityOwnerGrade,
            label: '점주 확정 등급',
            value: ownerGrade,
            items: const ['A', 'B', 'C'],
            onChanged: (value) {
              if (value != null) setState(() => ownerGrade = value);
            },
          ),
          LabeledDropdown(
            key: DemoTargetKeys.qualityOwnerDecision,
            label: '점주 판정',
            value: ownerDecision,
            items: const ['PASS', 'HOLD', 'REJECT'],
            onChanged: (value) {
              if (value != null) setState(() => ownerDecision = value);
            },
          ),
          DualActionBar(
            leftKey: DemoTargetKeys.qualityAnalyze,
            rightKey: DemoTargetKeys.qualitySave,
            left: isAnalyzing ? '분석 중' : '분석',
            right: isSaving ? '저장 중' : '저장',
            onLeftPressed: isAnalyzing ? null : _analyze,
            onRightPressed: isSaving ? null : _saveInspection,
          ),
        ],
      ),
    );
  }
}
