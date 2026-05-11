import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProcurementDetailPage extends StatefulWidget {
  const ProcurementDetailPage({super.key, required this.procurement});

  final OwnerProcurementRequestRecord procurement;

  @override
  State<ProcurementDetailPage> createState() => _ProcurementDetailPageState();
}

class _ProcurementDetailPageState extends State<ProcurementDetailPage> {
  final repository = OwnerWorkflowRepository();
  final rejectReasonController = TextEditingController();
  late final List<_EditableProcurementItem> items;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    items = [
      for (final item in widget.procurement.items)
        _EditableProcurementItem.fromRecord(item),
    ];
  }

  @override
  void dispose() {
    rejectReasonController.dispose();
    for (final item in items) {
      item.memoController.dispose();
    }
    super.dispose();
  }

  String get _decision {
    if (items.every(
      (item) => item.approvedPackageCount <= 0 || item.approvedKg <= 0,
    )) {
      return 'REJECTED';
    }
    if (items.every(
      (item) =>
          item.approvedPackageCount == item.requestedPackageCount &&
          item.approvedKg == item.requestedKg,
    )) {
      return 'APPROVED';
    }
    return 'PARTIAL_APPROVED';
  }

  Future<void> _submit() async {
    if (items.isEmpty) {
      showOwnerSnack(context, '결정할 발주 품목이 없습니다.');
      return;
    }
    final decision = _decision;
    if (decision == 'REJECTED' && rejectReasonController.text.trim().isEmpty) {
      showOwnerSnack(context, '전체 거절 시 거절 사유를 입력하세요.');
      return;
    }

    await showConfirmAction(
      context: context,
      title: '발주 결정',
      message: '${_decisionLabel(decision)} 처리할까요?',
      confirmLabel: '저장',
      onConfirm: () async {
        setState(() => isSubmitting = true);
        final saved = await repository.decideProcurement(
          request: widget.procurement,
          decision: decision,
          rejectedReason: decision == 'REJECTED'
              ? rejectReasonController.text.trim()
              : null,
          decisionItems: [
            for (final item in items)
              OwnerProcurementDecisionItem(
                procurementItemId: item.procurementItemId,
                approvedPackageCount: item.approvedPackageCount,
                approvedKg: item.approvedKg,
                ownerMemo: item.memoController.text.trim().isEmpty
                    ? null
                    : item.memoController.text.trim(),
              ),
          ],
        );
        if (!mounted) return;
        setState(() => isSubmitting = false);
        if (saved) {
          showOwnerSnack(context, '발주 결정을 저장했습니다.');
          Navigator.of(context).pop(true);
        } else {
          showOwnerSnack(context, '발주 결정을 저장하지 못했습니다.');
        }
      },
    );
  }

  void _rejectAll() {
    setState(() {
      for (final item in items) {
        item.approvedPackageCount = 0;
        item.approvedKg = 0;
      }
    });
  }

  void _approveAll() {
    setState(() {
      for (final item in items) {
        item.approvedPackageCount = item.requestedPackageCount;
        item.approvedKg = item.requestedKg;
      }
      rejectReasonController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final decision = _decision;

    return Scaffold(
      body: AppScaffold(
        title: '발주 상세',
        subtitle: widget.procurement.title,
        leading: ActionChipIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        children: [
          DataTile(
            icon: Icons.inventory_2_outlined,
            title: widget.procurement.status,
            subtitle: widget.procurement.subtitle,
            badge: _decisionLabel(decision),
            badgeColor: decision == 'REJECTED'
                ? const Color(0xffFFE1DD)
                : decision == 'PARTIAL_APPROVED'
                ? AppColors.yellow
                : AppColors.mint,
          ),
          SizedBox(
            key: DemoTargetKeys.procurementApproveAll,
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _approveAll,
                    child: const Text('전체 승인'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _rejectAll,
                    child: const Text('전체 거절'),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < items.length; index++)
            _ProcurementItemEditor(
              key: index == 0 ? DemoTargetKeys.procurementItemQuantity : null,
              item: items[index],
              onChanged: () => setState(() {}),
            ),
          if (decision == 'REJECTED')
            LabeledBox(
              label: '거절 사유',
              value: '',
              controller: rejectReasonController,
              hintText: '재고 부족, 품질 기준 미달 등',
              showCounter: true,
            ),
          DualActionBar(
            rightKey: DemoTargetKeys.procurementSave,
            left: '취소',
            right: isSubmitting ? '저장 중' : '결정 저장',
            onLeftPressed: () => Navigator.of(context).pop(false),
            onRightPressed: isSubmitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ProcurementItemEditor extends StatelessWidget {
  const _ProcurementItemEditor({
    super.key,
    required this.item,
    required this.onChanged,
  });

  final _EditableProcurementItem item;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.productName,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '요청 ${item.requestedPackageCount}박스 · ${item.requestedKg.toStringAsFixed(0)}kg',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LabeledNumberStepper(
            label: '승인 포장 개수',
            value: item.approvedPackageCount,
            min: 0,
            max: item.requestedPackageCount,
            suffixText: '박스',
            onChanged: (value) {
              item.approvedPackageCount = value;
              onChanged();
            },
          ),
          LabeledNumberStepper(
            label: '승인 kg',
            value: item.approvedKg.round(),
            min: 0,
            max: item.requestedKg.round(),
            suffixText: 'kg',
            onChanged: (value) {
              item.approvedKg = value.toDouble();
              onChanged();
            },
          ),
          LabeledBox(
            label: '점주 메모',
            value: '',
            controller: item.memoController,
            required: false,
            hintText: '품목별 확인 메모',
            showCounter: true,
          ),
        ],
      ),
    );
  }
}

class _EditableProcurementItem {
  _EditableProcurementItem({
    required this.procurementItemId,
    required this.productName,
    required this.requestedPackageCount,
    required this.requestedKg,
    required this.approvedPackageCount,
    required this.approvedKg,
  });

  final int procurementItemId;
  final String productName;
  final int requestedPackageCount;
  final double requestedKg;
  int approvedPackageCount;
  double approvedKg;
  final memoController = TextEditingController();

  factory _EditableProcurementItem.fromRecord(OwnerProcurementItemRecord item) {
    return _EditableProcurementItem(
      procurementItemId: item.procurementItemId,
      productName: item.productName,
      requestedPackageCount: item.requestedPackageCount,
      requestedKg: item.requestedKg,
      approvedPackageCount: item.requestedPackageCount,
      approvedKg: item.requestedKg,
    );
  }
}

String _decisionLabel(String decision) {
  return switch (decision) {
    'APPROVED' => '승인',
    'PARTIAL_APPROVED' => '부분승인',
    'REJECTED' => '거절',
    _ => decision,
  };
}
