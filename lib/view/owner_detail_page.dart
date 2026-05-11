import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_profile.dart';
import 'package:smart_app/repositories/owner_repository.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class OwnerDetailPage extends StatefulWidget {
  const OwnerDetailPage({super.key});

  @override
  State<OwnerDetailPage> createState() => _OwnerDetailPageState();
}

class _OwnerDetailPageState extends State<OwnerDetailPage> {
  final repository = OwnerRepository();
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final businessController = TextEditingController();
  OwnerProfile? profile;
  bool loading = true;
  bool saving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    businessController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final loaded = await repository.fetchProfile();
      if (!mounted) return;
      profile = loaded;
      nameController.text = loaded.ownerName;
      emailController.text = loaded.email;
      phoneController.text = loaded.ownerPhone;
      businessController.text = loaded.businessNumber ?? '';
    } on ApiException catch (error) {
      if (!mounted) return;
      errorMessage = error.message;
    } catch (_) {
      if (!mounted) return;
      errorMessage = '내 정보를 불러오지 못했습니다.';
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    showConfirmAction(
      context: context,
      title: '내 정보 저장',
      message: '입력한 내 정보로 저장할까요?',
      confirmLabel: '확인',
      onConfirm: _submitSave,
    );
  }

  Future<void> _submitSave() async {
    setState(() => saving = true);
    try {
      final saved = await repository.updateProfile(
        ownerName: nameController.text.trim(),
        ownerPhone: phoneController.text.trim(),
        businessNumber: businessController.text.trim(),
      );
      if (!mounted) return;
      profile = saved;
      showInfoAction(
        context: context,
        title: '내 정보 저장',
        message: '저장이 완료되었습니다.',
        onConfirm: () => Navigator.of(context).pop(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '내 정보 저장',
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '내 정보 저장',
        message: '저장하지 못했습니다.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '내 정보 수정',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: loading
              ? const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ]
              : errorMessage != null
              ? [
                  DataTile(
                    icon: Icons.error_outline,
                    title: '내 정보 불러오기 실패',
                    subtitle: errorMessage!,
                    badge: '재시도',
                    badgeColor: const Color(0xffFFE1DD),
                    onTap: _loadProfile,
                  ),
                ]
              : [
                  LabeledField(
                    key: DemoTargetKeys.ownerDetailName,
                    label: '이름',
                    value: '',
                    controller: nameController,
                    hintText: '이름',
                    validator: nameValidator,
                  ),
                  LabeledField(
                    label: '이메일',
                    value: '',
                    controller: emailController,
                    hintText: '이메일',
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true,
                  ),
                  LabeledField(
                    key: DemoTargetKeys.ownerDetailPhone,
                    label: '전화번호',
                    value: '',
                    controller: phoneController,
                    hintText: '전화번호',
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    inputFormatters: const [DigitsOnlyInputFormatter()],
                    validator: phoneValidator,
                  ),
                  LabeledField(
                    label: '사업자번호',
                    value: '',
                    controller: businessController,
                    hintText: '사업자번호',
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: const [DigitsOnlyInputFormatter()],
                    validator: businessValidator,
                  ),
                  DualActionBar(
                    left: '취소',
                    right: saving ? '저장 중' : '저장',
                    rightKey: DemoTargetKeys.ownerDetailSave,
                    onLeftPressed: () => Navigator.of(context).pop(),
                    onRightPressed: saving ? null : _save,
                  ),
                ],
        ),
      ),
    );
  }
}
