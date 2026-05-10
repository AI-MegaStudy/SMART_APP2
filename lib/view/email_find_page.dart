import 'package:flutter/material.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class EmailFindPage extends StatefulWidget {
  const EmailFindPage({super.key});

  @override
  State<EmailFindPage> createState() => _EmailFindPageState();
}

class _EmailFindPageState extends State<EmailFindPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _find() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final maskedPhone = phoneController.text.length >= 4
        ? '***-****-${phoneController.text.substring(phoneController.text.length - 4)}'
        : phoneController.text;
    showInfoAction(
      context: context,
      title: '이메일 찾기',
      message: '${nameController.text.trim()}님의 점주 계정을 확인했습니다. 등록된 연락처 $maskedPhone로 이메일 안내를 발송합니다.',
    );
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
