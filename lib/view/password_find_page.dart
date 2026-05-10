import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/repositories/auth_repository.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class PasswordFindPage extends StatefulWidget {
  const PasswordFindPage({super.key});

  @override
  State<PasswordFindPage> createState() => _PasswordFindPageState();
}

class _PasswordFindPageState extends State<PasswordFindPage> {
  final formKey = GlobalKey<FormState>();
  final repository = AuthRepository();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  bool isLoading = false;
  bool codeSent = false;
  String? devCode;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isLoading = true);
    try {
      final receivedDevCode = await repository.requestPasswordReset(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        codeSent = true;
        devCode = receivedDevCode;
      });
      final suffix = receivedDevCode == null || receivedDevCode.isEmpty
          ? ''
          : '\n개발 확인 코드: $receivedDevCode';
      showInfoAction(
        context: context,
        title: '비밀번호 찾기',
        message: '${emailController.text.trim()}로 인증번호를 발송했습니다.$suffix',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showOwnerSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showOwnerSnack(context, '계정 정보를 확인하지 못했습니다.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (passwordController.text != passwordConfirmController.text) {
      showOwnerSnack(context, '새 비밀번호가 일치하지 않습니다.');
      return;
    }
    setState(() => isLoading = true);
    try {
      await repository.confirmPasswordReset(
        email: emailController.text.trim(),
        code: codeController.text.trim(),
        newPassword: passwordController.text,
      );
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '비밀번호 재설정',
        message: '새 비밀번호가 저장되었습니다. 로그인 화면에서 다시 로그인하세요.',
        onConfirm: () => Navigator.of(context).pop(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showOwnerSnack(context, error.message);
    } catch (_) {
      if (!mounted) return;
      showOwnerSnack(context, '비밀번호를 재설정하지 못했습니다.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '비밀번호 찾기',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: [
            LabeledField(
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
              validator: emailValidator,
            ),
            if (codeSent) ...[
              if (devCode?.isNotEmpty == true)
                NoticeBox(
                  color: const Color(0xffEEF6FF),
                  text: '개발 확인 코드: $devCode',
                ),
              LabeledField(
                label: '인증번호',
                value: '',
                controller: codeController,
                hintText: '6자리 인증번호',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (!RegExp(r'^\d{6}$').hasMatch(text)) {
                    return '6자리 인증번호를 입력하세요.';
                  }
                  return null;
                },
              ),
              LabeledField(
                label: '새 비밀번호',
                value: '',
                controller: passwordController,
                hintText: '영문과 숫자 포함 8~20자',
                obscureText: true,
                validator: passwordValidator,
              ),
              LabeledField(
                label: '새 비밀번호 확인',
                value: '',
                controller: passwordConfirmController,
                hintText: '새 비밀번호 재입력',
                obscureText: true,
                validator: passwordValidator,
              ),
            ],
            DualActionBar(
              left: '취소',
              right: isLoading
                  ? '처리 중'
                  : codeSent
                  ? '비밀번호 저장'
                  : '인증번호 발송',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isLoading
                  ? null
                  : codeSent
                  ? _confirmReset
                  : _requestReset,
            ),
          ],
        ),
      ),
    );
  }
}
