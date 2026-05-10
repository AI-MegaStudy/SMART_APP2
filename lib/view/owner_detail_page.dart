import 'package:flutter/material.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class OwnerDetailPage extends StatefulWidget {
  const OwnerDetailPage({super.key});

  @override
  State<OwnerDetailPage> createState() => _OwnerDetailPageState();
}

class _OwnerDetailPageState extends State<OwnerDetailPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: '김하늘');
  final emailController = TextEditingController(text: 'owner@harvestslot.kr');
  final passwordController = TextEditingController(text: 'owner1234');
  final passwordConfirmController = TextEditingController(text: 'owner1234');
  final phoneController = TextEditingController(text: '1022223344');
  final businessController = TextEditingController(text: '3124567890');

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();
    phoneController.dispose();
    businessController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    showConfirmAction(
      context: context,
      title: '내 정보 저장',
      message: '입력한 내 정보로 저장할까요?',
      confirmLabel: '확인',
      onConfirm: () => showInfoAction(
        context: context,
        title: '내 정보 저장',
        message: '저장이 완료되었습니다.',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
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
            DualActionBar(
              left: '취소',
              right: '저장',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
