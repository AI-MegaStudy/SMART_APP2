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
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isLoading = true);
    try {
      final devCode = await repository.requestPasswordReset(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );
      if (!mounted) return;
      final suffix = devCode == null || devCode.isEmpty
          ? ''
          : '\n개발 확인 코드: $devCode';
      showInfoAction(
        context: context,
        title: '비밀번호 찾기',
        message: '${emailController.text.trim()}로 비밀번호 재설정 안내를 발송했습니다.$suffix',
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
              right: isLoading ? '발송 중' : '찾기',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isLoading ? null : _find,
            ),
          ],
        ),
      ),
    );
  }
}
