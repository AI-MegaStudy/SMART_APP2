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
    final visible = <OwnerStatusRecord>[...returnStatusRecords, ...records]
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
            labels: const ['전체', '승인', '거절'],
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

final returnStatusRecords = <ReturnStatusRecord>[
  const ReturnStatusRecord(
    '2026-05-07 10:30',
    '김민지 · 부사 사과 3kg · 1박스 · 12,000원',
    '승인',
    AppColors.mint,
  ),
  const ReturnStatusRecord(
    '2026-05-07 11:10',
    '박서준 · 양광 사과 7kg · 1박스 · 정책상 거절',
    '거절',
    AppColors.yellow,
  ),
];

class ReturnStatusRecord extends OwnerStatusRecord {
  const ReturnStatusRecord(
    String title,
    String subtitle,
    String status,
    this.overrideColor,
  ) : super(title: title, subtitle: subtitle, status: status);

  final Color overrideColor;

  @override
  Color get color => overrideColor;
}
