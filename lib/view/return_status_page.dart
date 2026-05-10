import 'package:flutter/material.dart';
import 'package:smart_app/model/owner_status_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ReturnStatusPage extends StatefulWidget {
  const ReturnStatusPage({super.key});

  @override
  State<ReturnStatusPage> createState() => _ReturnStatusPageState();
}

class _ReturnStatusPageState extends State<ReturnStatusPage> {
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
    final loaded = await repository.fetchReturnStatuses();
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
        title: '반품 · 환불 현황',
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
                hintText: '반품 사유, 상품명, 상태를 검색하세요',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          FilterTabs(
            labels: const ['전체', '접수', '승인', '거절'],
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
                icon: Icons.assignment_return_outlined,
                title: '표시할 반품 현황이 없습니다.',
                message: '고객 반품 요청이 들어오면 접수, 승인, 거절 상태를 이곳에서 확인합니다.',
              ),
          if (!loading)
            for (final item in visible)
              DataTile(
                icon: Icons.assignment_return_outlined,
                title: item.title,
                subtitle: item.subtitle,
                badge: item.status,
                badgeColor: item.color,
                iconBackground: AppColors.mint,
                iconColor: AppColors.green,
              ),
        ],
      ),
    );
  }
}
