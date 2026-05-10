import 'package:flutter/material.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final repository = OwnerWorkflowRepository();
  final searchController = TextEditingController();
  String filter = '전체';
  bool showSearch = false;
  bool loading = true;
  List<OwnerOrderRecord> orders = const [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => loading = true);
    final loaded = await repository.fetchOrders();
    if (!mounted) return;
    setState(() {
      orders = loaded;
      sharedOwnerOrders = loaded;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visible = orders.where((order) {
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
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (!loading)
            for (final order in visible)
              DataTile(
                icon: Icons.receipt_long_outlined,
                title: order.title,
                subtitle: order.subtitle,
                badge: order.status,
                badgeColor: order.color,
              ),
          if (!loading && visible.isEmpty)
            const NoticeBox(color: AppColors.yellow, text: '검색 결과가 없습니다.'),
        ],
      ),
    );
  }
}

List<OwnerOrderRecord> sharedOwnerOrders = const [];
