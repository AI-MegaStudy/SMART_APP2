import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kpostal_plus/kpostal_plus.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/repositories/auth_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final repository = AuthRepository();
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailLocalController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  final phoneController = TextEditingController();
  final businessController = TextEditingController();
  final farmController = TextEditingController();
  final addressController = TextEditingController();
  final verificationCodeController = TextEditingController();
  final emailFocusNode = FocusNode();

  bool verificationSent = false;
  bool emailVerified = false;
  bool submitting = false;

  static const fallbackAddresses = [
    '충북 충주시 산척면 과수원길 24',
    '충북 충주시 주덕읍 냇내로 18',
    '충북 충주시 동량면 사과밭길 7',
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailLocalController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    phoneController.dispose();
    businessController.dispose();
    farmController.dispose();
    addressController.dispose();
    verificationCodeController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  String get fullEmail => emailLocalController.text.trim();

  Future<void> _sendVerification() async {
    final missingLocal = emailLocalController.text.trim().isEmpty;
    final invalidEmail = emailValidator(emailLocalController.text) != null;
    if (missingLocal || invalidEmail) {
      formKey.currentState?.validate();
      emailFocusNode.requestFocus();
      return;
    }

    try {
      await repository.sendEmailVerification(fullEmail);
      if (!mounted) return;
      setState(() {
        verificationSent = true;
        emailVerified = false;
      });
      showInfoAction(
        context: context,
        title: '이메일 인증',
        message: '인증번호를 발송했습니다.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showInfoAction(context: context, title: '이메일 인증', message: error.message);
    } catch (_) {
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '이메일 인증',
        message: '인증번호를 발송하지 못했습니다.',
      );
    }
  }

  Future<void> _verifyEmail() async {
    final code = verificationCodeController.text.trim();
    if (code.isEmpty) {
      showInfoAction(
        context: context,
        title: '이메일 인증',
        message: '인증번호를 입력하세요.',
      );
      return;
    }
    try {
      await repository.verifyEmail(email: fullEmail, code: code);
      if (!mounted) return;
      setState(() => emailVerified = true);
      showInfoAction(
        context: context,
        title: '이메일 인증',
        message: '이메일 인증이 완료되었습니다.',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showInfoAction(context: context, title: '이메일 인증', message: error.message);
    } catch (_) {
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '이메일 인증',
        message: '이메일 인증을 완료하지 못했습니다.',
      );
    }
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

  void _submit() {
    final missingEmail = emailLocalController.text.trim().isEmpty;
    final valid = formKey.currentState?.validate() ?? false;
    if (!valid || missingEmail) {
      if (emailLocalController.text.trim().isEmpty) {
        emailFocusNode.requestFocus();
      }
      return;
    }
    if (!emailVerified) {
      showInfoAction(
        context: context,
        title: '이메일 인증',
        message: '이메일 인증을 먼저 완료하세요.',
      );
      return;
    }
    showConfirmAction(
      context: context,
      title: '회원가입',
      message: '입력한 정보로 계정을 생성할까요?',
      confirmLabel: '확인',
      onConfirm: _submitSignup,
    );
  }

  Future<void> _submitSignup() async {
    setState(() => submitting = true);
    try {
      await repository.signupOwner(
        email: fullEmail,
        password: passwordController.text,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '회원가입',
        message: '회원가입이 완료되었습니다. 로그인 후 농장 정보를 확인하세요.',
        onConfirm: () => Navigator.of(context).pop(),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      showInfoAction(context: context, title: '회원가입', message: error.message);
    } catch (_) {
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '회원가입',
        message: '회원가입을 완료하지 못했습니다.',
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '회원가입',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: [
            const SectionHeader(title: '내 정보'),
            LabeledField(
              label: '이름',
              value: '',
              controller: nameController,
              hintText: '이름',
              validator: nameValidator,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: '이메일',
                        value: '',
                        controller: emailLocalController,
                        focusNode: emailFocusNode,
                        hintText: '이메일',
                        keyboardType: TextInputType.emailAddress,
                        validator: emailValidator,
                        onChanged: (_) {
                          setState(() {
                            verificationSent = false;
                            emailVerified = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.tonal(
                    onPressed: _sendVerification,
                    child: const Text('인증번호 발송', maxLines: 1, softWrap: false),
                  ),
                ),
                if (verificationSent) ...[
                  const SizedBox(height: 8),
                  LabeledField(
                    label: '인증번호',
                    value: '',
                    controller: verificationCodeController,
                    hintText: '인증번호',
                    keyboardType: TextInputType.number,
                    inputFormatters: const [DigitsOnlyInputFormatter()],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.tonal(
                      onPressed: emailVerified ? null : _verifyEmail,
                      child: Text(emailVerified ? '인증 완료' : '인증 확인'),
                    ),
                  ),
                ],
              ],
            ),
            LabeledField(
              label: '비밀번호',
              value: '',
              controller: passwordController,
              hintText: '비밀번호',
              helperText: '영문과 숫자를 포함해 8~20자',
              obscureText: true,
              validator: passwordValidator,
            ),
            LabeledField(
              label: '비밀번호 확인',
              value: '',
              controller: passwordConfirmController,
              hintText: '비밀번호 확인',
              obscureText: true,
              validator: (value) {
                final required = requiredValidator('비밀번호 확인', value);
                if (required != null) return required;
                return value == passwordController.text
                    ? null
                    : '비밀번호가 일치하지 않습니다.';
              },
            ),
            LabeledField(
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
            const SizedBox(height: 6),
            const SectionHeader(title: '농장 정보'),
            LabeledField(
              label: '농장명',
              value: '',
              controller: farmController,
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
            DualActionBar(
              left: '취소',
              right: submitting ? '처리 중' : '회원가입',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
