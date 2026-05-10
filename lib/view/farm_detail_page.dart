import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kpostal_plus/kpostal_plus.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class FarmDetailPage extends StatefulWidget {
  const FarmDetailPage({super.key});

  @override
  State<FarmDetailPage> createState() => _FarmDetailPageState();
}

class _FarmDetailPageState extends State<FarmDetailPage> {
  final formKey = GlobalKey<FormState>();
  final farmNameController = TextEditingController(text: '충주 햇살농원');
  final addressController = TextEditingController(text: '충북 충주시 산척면 과수원길 24');
  final introController = TextEditingController();
  final shippingPolicyController = TextEditingController();
  final returnPolicyController = TextEditingController();
  static const fallbackAddresses = [
    '충북 충주시 산척면 과수원길 24',
    '충북 충주시 주덕읍 냇내로 18',
    '충북 충주시 동량면 사과밭길 7',
  ];

  @override
  void dispose() {
    farmNameController.dispose();
    addressController.dispose();
    introController.dispose();
    shippingPolicyController.dispose();
    returnPolicyController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(formKey.currentState?.validate() ?? false)) return;
    showConfirmAction(
      context: context,
      title: '농장 정보 저장',
      message: '입력한 농장 정보로 저장할까요?',
      onConfirm: () => showInfoAction(
        context: context,
        title: '농장 정보 저장',
        message: '저장이 완료되었습니다.',
        onConfirm: () => Navigator.of(context).pop(),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: AppScaffold(
          title: '농장 정보 수정',
          leading: ActionChipIcon(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
          children: [
            LabeledField(
              label: '농장명',
              value: '',
              controller: farmNameController,
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
            LabeledBox(
              label: '농장 소개',
              value: '',
              controller: introController,
              required: false,
              showCounter: true,
            ),
            LabeledBox(
              label: '배송 정책',
              value: '',
              controller: shippingPolicyController,
              required: false,
              showCounter: true,
            ),
            LabeledBox(
              label: '반품 정책',
              value: '',
              controller: returnPolicyController,
              required: false,
              showCounter: true,
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
