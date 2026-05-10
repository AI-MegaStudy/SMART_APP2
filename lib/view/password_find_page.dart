import 'package:flutter/material.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class PasswordFindPage extends StatefulWidget {
  const PasswordFindPage({super.key});

  @override
  State<PasswordFindPage> createState() => _PasswordFindPageState();
}

class _PasswordFindPageState extends State<PasswordFindPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _find() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    showInfoAction(
      context: context,
      title: '비밀번호 찾기',
      message: '현재 백엔드에 비밀번호 재설정 API가 없어 처리할 수 없습니다. 관리자에게 초기화를 요청하세요.',
    );
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
            DualActionBar(
              left: '취소',
              right: '찾기',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: _find,
            ),
          ],
        ),
      ),
    );
  }
}
