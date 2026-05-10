import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ReturnStatusPage extends StatefulWidget {
  const ReturnStatusPage({super.key});

  @override
  State<ReturnStatusPage> createState() => _ReturnStatusPageState();
}

class _ReturnStatusPageState extends State<ReturnStatusPage> {
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
    final visible = returnStatusRecords.where((item) {
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
            labels: const ['전체', '승인', '거절'],
            selected: filter,
            onChanged: (value) => setState(() => filter = value),
          ),
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

class ReturnStatusRecord {
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const ReturnStatusRecord(this.title, this.subtitle, this.status, this.color);
}
