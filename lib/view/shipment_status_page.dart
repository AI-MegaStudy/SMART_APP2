import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_status_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ShipmentStatusPage extends StatefulWidget {
  const ShipmentStatusPage({super.key});

  @override
  State<ShipmentStatusPage> createState() => _ShipmentStatusPageState();
}

class _ShipmentStatusPageState extends State<ShipmentStatusPage> {
  final repository = OwnerWorkflowRepository();
  final searchController = TextEditingController();
  String filter = '전체';
  bool showSearch = false;
  bool loading = true;
  List<OwnerStatusRecord> records = const [];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => loading = true);
    final loaded = await repository.fetchShipmentStatuses();
    if (!mounted) return;
    setState(() {
      records = loaded;
      loading = false;
    });
  }

  Future<void> _openShipmentAction(OwnerStatusRecord record) async {
    final nextStatus = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  record.subtitle,
                  style: const TextStyle(
                    color: Color(0xff6F7D68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                _ShipmentActionTile(
                  icon: Icons.local_shipping_outlined,
                  title: '배송 중으로 표시',
                  subtitle: '송장 접수 후 이동 중인 상태',
                  onTap: () => Navigator.of(context).pop('SHIPPED'),
                ),
                const SizedBox(height: 10),
                _ShipmentActionTile(
                  icon: Icons.check_circle_outline,
                  title: '배송 완료로 표시',
                  subtitle: '고객에게 배송이 완료된 상태',
                  onTap: () => Navigator.of(context).pop('DELIVERED'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (nextStatus == null || !mounted) return;
    if (record.isFallback || record.shipmentId == null) {
      final label = nextStatus == 'DELIVERED' ? '배송 완료' : '배송 중';
      setState(() {
        records = [
          for (final item in records)
            if (identical(item, record))
              item.copyWith(status: label, rawStatus: nextStatus)
            else
              item,
        ];
      });
      showOwnerSnack(context, '배송 상태를 갱신했습니다.');
      return;
    }

    final updated = await repository.updateShipmentStatus(
      shipmentId: record.shipmentId!,
      shipmentStatus: nextStatus,
    );
    if (!mounted) return;
    if (updated) {
      await _loadRecords();
      if (!mounted) return;
      showOwnerSnack(context, '배송 상태를 갱신했습니다.');
    } else {
      showOwnerSnack(context, '배송 상태를 변경하지 못했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = records.where((item) {
      final matchesFilter = filter == '전체' || item.status == filter;
      final matchesQuery =
          query.isEmpty ||
          '${item.title} ${item.subtitle} ${item.status}'
              .toLowerCase()
              .contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      body: AppScaffold(
        title: '배송 현황',
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
                hintText: '배송 상품, 송장번호, 상태를 검색하세요',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          FilterTabs(
            labels: const ['전체', '배송 대기', '배송 중', '배송 완료'],
            selected: filter,
            onChanged: (value) => setState(() => filter = value),
          ),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!loading)
            if (visible.isEmpty)
              const EmptyState(
                icon: Icons.local_shipping_outlined,
                title: '표시할 배송 현황이 없습니다.',
                message: '배송 등록이 완료되면 송장과 배송 상태를 이곳에서 관리합니다.',
              ),
          if (!loading)
            for (final entry in visible.indexed)
              DataTile(
                key: entry.$1 == 0 ? DemoTargetKeys.shipmentStatusItem : null,
                icon: Icons.local_shipping_outlined,
                title: entry.$2.title,
                subtitle: entry.$2.subtitle,
                badge: entry.$2.status,
                badgeColor: entry.$2.color,
                showChevron: true,
                onTap: () => _openShipmentAction(entry.$2),
              ),
        ],
      ),
    );
  }
}

class _ShipmentActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShipmentActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffF7FAF4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xff244330)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xff6F7D68),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xff6F7D68)),
            ],
          ),
        ),
      ),
    );
  }
}
