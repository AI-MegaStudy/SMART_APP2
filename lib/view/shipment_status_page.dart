import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class ShipmentStatusPage extends StatefulWidget {
  const ShipmentStatusPage({super.key});

  @override
  State<ShipmentStatusPage> createState() => _ShipmentStatusPageState();
}

class _ShipmentStatusPageState extends State<ShipmentStatusPage> {
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
    final visible = shipmentStatusRecords.where((item) {
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

final shipmentStatusRecords = <ShipmentRecord>[
  const ShipmentRecord(
    '홍길동 · 양광 사과 5kg · 2박스',
    'CJ대한통운 · 589112024810',
    '배송 중',
    AppColors.mint,
  ),
  const ShipmentRecord(
    '김민지 · 부사 사과 3kg · 1박스',
    '우체국택배 · 451290880221',
    '배송 대기',
    AppColors.yellow,
  ),
  const ShipmentRecord(
    '박서준 · 양광 사과 7kg · 1박스',
    '롯데택배 · 123412341234',
    '배송 완료',
    AppColors.blue,
  ),
];

class ShipmentRecord {
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const ShipmentRecord(this.title, this.subtitle, this.status, this.color);
}
