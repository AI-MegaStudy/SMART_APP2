import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/view/orders_page.dart';
import 'package:smart_app/view/procurement_status_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProcurementPage extends StatefulWidget {
  const ProcurementPage({super.key});

  @override
  State<ProcurementPage> createState() => _ProcurementPageState();
}

class _ProcurementPageState extends State<ProcurementPage> {
  final searchController = TextEditingController();
  final selectedIds = <String>{};
  bool showSearch = false;
  late final requests =
      [
          for (var i = 0; i < sampleOrders.length; i++)
            _ApprovalRequest(
              'order-$i',
              sampleOrders[i].title,
              sampleOrders[i].subtitle,
              sampleOrders[i].status,
              sampleOrders[i].status == '결제 완료',
              sampleOrders[i].time,
              sampleOrders[i].amount,
            ),
        ].where((item) => !_handledProcurementIds.contains(item.id)).toList()
        ..sort((a, b) {
          if (a.enabled != b.enabled) {
            return a.enabled ? -1 : 1;
          }
          return a.time.compareTo(b.time);
        });

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

  void _applyDecision(String status, {String? reason}) {
    final handled = requests
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);
    procurementStatusRecords.addAll([
      for (final item in handled)
        ProcurementStatusRecord(
          '2026-05-08 ${item.time}',
          reason == null
              ? '${item.title} · ${_withoutDateTime(item.subtitle)}'
              : '${item.title} · ${_boxCount(item.subtitle)} · $reason',
          status,
          status == '승인' ? AppColors.mint : const Color(0xffFFE1DD),
        ),
    ]);
    setState(() {
      requests.removeWhere((item) => selectedIds.contains(item.id));
      _handledProcurementIds.addAll(selectedIds);
      selectedIds.clear();
    });
    showOwnerSnack(context, '발주 현황을 갱신했습니다.');
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
          for (final request in visible)
            _ApprovalTile(
              request: request,
              selected: selectedIds.contains(request.id),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    selectedIds.add(request.id);
                  } else {
                    selectedIds.remove(request.id);
                  }
                });
              },
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _toggleAll(!allSelected),
              child: Text(allSelected ? '전체 선택 해제' : '전체 선택'),
            ),
          ),
          DualActionBar(
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

String _withoutDateTime(String text) {
  return text.replaceAll(RegExp(r' · \d{4}-\d{2}-\d{2} \d{2}:\d{2}$'), '');
}

String _boxCount(String text) {
  return RegExp(r'\d+박스').firstMatch(text)?.group(0) ?? '1박스';
}

final _handledProcurementIds = <String>{};

class _ApprovalTile extends StatelessWidget {
  final _ApprovalRequest request;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const _ApprovalTile({
    required this.request,
    required this.selected,
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
        child: CheckboxListTile(
          value: selected,
          onChanged: request.enabled ? onChanged : null,
          title: Text(
            '${request.title} · ${request.status}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(request.subtitle),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }
}

class _ApprovalRequest {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final bool enabled;
  final String time;
  final String amount;

  const _ApprovalRequest(
    this.id,
    this.title,
    this.subtitle,
    this.status,
    this.enabled,
    this.time,
    this.amount,
  );
}
