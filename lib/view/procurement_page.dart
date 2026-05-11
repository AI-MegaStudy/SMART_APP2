import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/view/procurement_detail_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProcurementPage extends StatefulWidget {
  final bool demoOpenFirst;

  const ProcurementPage({super.key, this.demoOpenFirst = false});

  @override
  State<ProcurementPage> createState() => _ProcurementPageState();
}

class _ProcurementPageState extends State<ProcurementPage> {
  final repository = OwnerWorkflowRepository();
  final searchController = TextEditingController();
  final selectedIds = <String>{};
  bool showSearch = false;
  bool loading = true;
  var requests = <_ApprovalRequest>[];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  List<_ApprovalRequest> get enabledRequests =>
      requests.where((item) => item.enabled).toList();

  bool get allSelected =>
      enabledRequests.isNotEmpty &&
      selectedIds.length == enabledRequests.length;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    final procurements = await repository.fetchProcurementRequests();
    if (!mounted) return;
    setState(() {
      requests = _requestsFromProcurements(procurements);
      loading = false;
    });
    if (widget.demoOpenFirst && requests.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 5400), () {
          if (!mounted || requests.isEmpty) return;
          _openDetail(requests.first);
        });
      });
    }
  }

  List<_ApprovalRequest> _requestsFromProcurements(
    List<OwnerProcurementRequestRecord> procurements,
  ) {
    return [
      for (final procurement in procurements) _ApprovalRequest(procurement),
    ].toList()..sort((a, b) {
      if (a.enabled != b.enabled) {
        return a.enabled ? -1 : 1;
      }
      return a.time.compareTo(b.time);
    });
  }

  void _toggleAll(bool? selected) {
    setState(() {
      selectedIds
        ..clear()
        ..addAll(
          selected == true
              ? enabledRequests.map((item) => item.id)
              : const <String>[],
        );
    });
  }

  void _confirmApprove() {
    if (selectedIds.isEmpty) {
      showOwnerSnack(context, '처리할 주문을 선택하세요.');
      return;
    }
    showConfirmAction(
      context: context,
      title: '발주 승인',
      message: '선택한 ${selectedIds.length}건을 승인 처리할까요?',
      confirmLabel: '승인',
      onConfirm: () => _applyDecision('승인'),
    );
  }

  Future<void> _confirmReject() async {
    if (selectedIds.isEmpty) {
      showOwnerSnack(context, '처리할 주문을 선택하세요.');
      return;
    }
    var reason = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('발주 거절'),
              content: DropdownButtonFormField<String>(
                initialValue: reason,
                items: const [
                  DropdownMenuItem(value: '', child: Text('선택하세요.')),
                  DropdownMenuItem(value: '재고 부족', child: Text('재고 부족')),
                  DropdownMenuItem(value: '품질 기준 미달', child: Text('품질 기준 미달')),
                  DropdownMenuItem(value: '출고 일정 불가', child: Text('출고 일정 불가')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => reason = value);
                  }
                },
                decoration: const InputDecoration(labelText: '거절 사유'),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('취소'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: reason.isEmpty
                            ? null
                            : () => Navigator.of(context).pop(true),
                        child: const Text('거절'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed == true) {
      _applyDecision('거절', reason: reason);
    }
  }

  Future<void> _applyDecision(String status, {String? reason}) async {
    final handled = requests
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);
    for (final item in handled) {
      await repository.decideProcurement(
        request: item.procurement,
        decision: status == '승인' ? 'APPROVED' : 'REJECTED',
        rejectedReason: reason,
      );
    }
    if (!mounted) return;
    setState(() {
      requests.removeWhere((item) => selectedIds.contains(item.id));
      selectedIds.clear();
    });
    await _loadRequests();
    if (!mounted) return;
    showOwnerSnack(context, '발주 현황을 갱신했습니다.');
  }

  Future<void> _openDetail(_ApprovalRequest request) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProcurementDetailPage(procurement: request.procurement),
      ),
    );
    if (updated == true) {
      await _loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = requests.where((request) {
      return query.isEmpty ||
          '${request.title} ${request.subtitle} ${request.status}'
              .toLowerCase()
              .contains(query);
    }).toList();

    return Scaffold(
      body: AppScaffold(
        title: '발주 승인',
        leading: ActionChipIcon(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        trailing: ActionChipIcon(
          icon: showSearch ? Icons.close : Icons.search,
          onPressed: () {
            setState(() {
              showSearch = !showSearch;
              if (!showSearch) {
                searchController.clear();
              }
            });
          },
        ),
        children: [
          if (showSearch)
            TextField(
              controller: searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '고객명, 상품명, 상태를 검색하세요',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!loading)
            for (var index = 0; index < visible.length; index++)
              _ApprovalTile(
                key: index == 0 ? DemoTargetKeys.procurementFirst : null,
                request: visible[index],
                selected: selectedIds.contains(visible[index].id),
                onTap: () => _openDetail(visible[index]),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      selectedIds.add(visible[index].id);
                    } else {
                      selectedIds.remove(visible[index].id);
                    }
                  });
                },
              ),
          if (!loading)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _toggleAll(!allSelected),
                child: Text(allSelected ? '전체 선택 해제' : '전체 선택'),
              ),
            ),
          if (!loading)
            DualActionBar(
              rightKey: DemoTargetKeys.procurementApprove,
              left: '거절',
              right: '승인',
              onLeftPressed: _confirmReject,
              onRightPressed: _confirmApprove,
            ),
        ],
      ),
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  final _ApprovalRequest request;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onChanged;

  const _ApprovalTile({
    super.key,
    required this.request,
    required this.selected,
    required this.onTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: request.enabled ? Colors.white : const Color(0xffF4F7F1),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: request.enabled ? onChanged : null,
            ),
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.title} · ${request.status}',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(request.subtitle),
                      const SizedBox(height: 8),
                      const Text(
                        '상세에서 품목별 수량과 메모를 조정하세요.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalRequest {
  const _ApprovalRequest(this.procurement);

  final OwnerProcurementRequestRecord procurement;

  String get id => procurement.id;
  String get title => procurement.title;
  String get subtitle => procurement.subtitle;
  String get status => procurement.status;
  bool get enabled => procurement.enabled;
  String get time => procurement.time;
  String get amount => procurement.amount;
}
