import 'package:flutter/material.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProcurementStatusPage extends StatefulWidget {
  const ProcurementStatusPage({super.key});

  @override
  State<ProcurementStatusPage> createState() => _ProcurementStatusPageState();
}

class _ProcurementStatusPageState extends State<ProcurementStatusPage> {
  final repository = OwnerWorkflowRepository();
  final searchController = TextEditingController();
  String filter = '전체';
  bool showSearch = false;
  bool loading = true;
  List<OwnerProcurementRequestRecord> records = const [];

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
    final loaded = await repository.fetchProcurementRequests();
    if (!mounted) return;
    setState(() {
      records = loaded;
      loading = false;
    });
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
        title: '발주 현황',
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
                hintText: '발주 상품, 고객명, 상태를 검색하세요',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          FilterTabs(
            labels: const ['전체', '승인 대기', '승인', '부분승인', '거절'],
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
          if (!loading && visible.isEmpty)
            const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: '표시할 발주 현황이 없습니다.',
              message: '새 주문이 들어오면 발주 승인 흐름에서 바로 확인할 수 있습니다.',
            ),
          if (!loading)
            for (final item in visible)
              DataTile(
                icon: Icons.inventory_2_outlined,
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
