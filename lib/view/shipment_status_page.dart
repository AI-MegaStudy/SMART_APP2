import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = <OwnerStatusRecord>[...shipmentStatusRecords, ...records]
        .where((item) {
          final matchesFilter = filter == '전체' || item.status == filter;
          final matchesQuery =
              query.isEmpty ||
              '${item.title} ${item.subtitle} ${item.status}'
                  .toLowerCase()
                  .contains(query);
          return matchesFilter && matchesQuery;
        })
        .toList();

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
            for (final item in visible)
              DataTile(
                icon: Icons.local_shipping_outlined,
                title: item.title,
                subtitle: item.subtitle,
                badge: item.status,
                badgeColor: item.color,
              ),
        ],
      ),
    );
  }
}

final shipmentStatusRecords = <ShipmentRecord>[];

class ShipmentRecord extends OwnerStatusRecord {
  const ShipmentRecord(
    String title,
    String subtitle,
    String status,
    this.overrideColor,
  ) : super(title: title, subtitle: subtitle, status: status);

  final Color overrideColor;

  @override
  Color get color => overrideColor;
}
