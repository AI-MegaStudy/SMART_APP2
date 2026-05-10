import 'package:flutter/material.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
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
    final visible = sampleOrders.where((order) {
      final matchesFilter = filter == '전체' || order.status == filter;
      final matchesQuery =
          query.isEmpty ||
          '${order.title} ${order.subtitle} ${order.status}'
              .toLowerCase()
              .contains(query);
      return matchesFilter && matchesQuery;
    }).toList()..sort((a, b) => a.time.compareTo(b.time));

    return Scaffold(
      body: AppScaffold(
        title: '주문 현황',
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
              decoration: InputDecoration(
                hintText: '고객명, 상품명, 상태를 검색하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          FilterTabs(
            labels: const ['전체', '주문 완료', '결제 완료'],
            selected: filter,
            onChanged: (value) => setState(() => filter = value),
          ),
          for (final order in visible)
            DataTile(
              icon: Icons.receipt_long_outlined,
              title: order.title,
              subtitle: order.subtitle,
              badge: order.status,
              badgeColor: order.color,
            ),
          if (visible.isEmpty)
            const NoticeBox(color: AppColors.yellow, text: '검색 결과가 없습니다.'),
        ],
      ),
    );
  }
}

const sampleOrders = [
  OrderRecord(
    '홍길동 · 양광 사과 5kg',
    '2박스 · 78,000원 · 2026-05-07 09:20',
    '결제 완료',
    AppColors.blue,
    '09:20',
    '78,000원',
  ),
  OrderRecord(
    '김민지 · 부사 사과 3kg',
    '1박스 · 32,000원 · 2026-05-07 09:45',
    '주문 완료',
    AppColors.yellow,
    '09:45',
    '32,000원',
  ),
  OrderRecord(
    '박서준 · 양광 사과 7kg',
    '1박스 · 68,000원 · 2026-05-07 12:10',
    '결제 완료',
    AppColors.blue,
    '12:10',
    '68,000원',
  ),
];

class OrderRecord {
  final String title;
  final String subtitle;
  final String status;
  final Color color;
  final String time;
  final String amount;

  const OrderRecord(
    this.title,
    this.subtitle,
    this.status,
    this.color,
    this.time,
    this.amount,
  );
}
