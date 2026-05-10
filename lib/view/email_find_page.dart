import 'package:flutter/material.dart';
import 'package:smart_app/core/api_exception.dart';
import 'package:smart_app/repositories/auth_repository.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class EmailFindPage extends StatefulWidget {
  const EmailFindPage({super.key});

  @override
  State<EmailFindPage> createState() => _EmailFindPageState();
}

class _EmailFindPageState extends State<EmailFindPage> {
  final formKey = GlobalKey<FormState>();
  final repository = AuthRepository();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isLoading = true);
    try {
      final maskedEmail = await repository.findEmail(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      if (!mounted) return;
      showInfoAction(
        context: context,
        title: '이메일 찾기',
        message: '등록된 점주 이메일은 $maskedEmail 입니다.',
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
          title: '이메일 찾기',
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
              label: '전화번호',
              value: '',
              controller: phoneController,
              hintText: '전화번호',
              keyboardType: TextInputType.number,
              maxLength: 11,
              inputFormatters: const [DigitsOnlyInputFormatter()],
              validator: phoneValidator,
            ),
            DualActionBar(
              left: '취소',
              right: isLoading ? '확인 중' : '찾기',
              onLeftPressed: () => Navigator.of(context).pop(),
              onRightPressed: isLoading ? null : _find,
            ),
          ],
        ),
      ),
    );
  }
}
