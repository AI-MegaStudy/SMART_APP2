import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ProcurementStatusPage extends StatefulWidget {
  const ProcurementStatusPage({super.key});

  @override
  State<ProcurementStatusPage> createState() => _ProcurementStatusPageState();
}

class _ProcurementStatusPageState extends State<ProcurementStatusPage> {
  final searchController = TextEditingController();
  String filter = '전체';
  bool showSearch = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = procurementStatusRecords.where((item) {
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
            labels: const ['전체', '승인', '거절'],
            selected: filter,
            onChanged: (value) => setState(() => filter = value),
          ),
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

final procurementStatusRecords = <ProcurementStatusRecord>[
  const ProcurementStatusRecord(
    '2026-05-07 10:10',
    '박서준 · 부사 사과 3kg · 1박스 · 68,000원',
    '승인',
    AppColors.mint,
  ),
  const ProcurementStatusRecord(
    '2026-05-07 10:20',
    '김민지 · 양광 사과 5kg · 1박스 · 재고 부족',
    '거절',
    Color(0xffFFE1DD),
  ),
];

class ProcurementStatusRecord {
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const ProcurementStatusRecord(
    this.title,
    this.subtitle,
    this.status,
    this.color,
  );
}
