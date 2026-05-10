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
  String section = '주문';
  bool showSearch = false;
  bool loading = true;
  List<OwnerOrderRecord> orders = const [];
  List<OwnerReservationRecord> reservations = const [];

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
    final loaded = await Future.wait<Object>([
      repository.fetchOrders(),
      repository.fetchReservations(),
    ]);
    if (!mounted) return;
    setState(() {
      orders = loaded[0] as List<OwnerOrderRecord>;
      reservations = loaded[1] as List<OwnerReservationRecord>;
      sharedOwnerOrders = orders;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final visibleOrders = orders.where((order) {
      final matchesFilter = filter == '전체' || order.status == filter;
      final matchesQuery =
          query.isEmpty ||
          '${order.title} ${order.subtitle} ${order.status}'
              .toLowerCase()
              .contains(query);
      return matchesFilter && matchesQuery;
    }).toList()..sort((a, b) => a.time.compareTo(b.time));
    final visibleReservations = reservations.where((reservation) {
      final matchesFilter = filter == '전체' || reservation.status == filter;
      final matchesQuery =
          query.isEmpty ||
          '${reservation.title} ${reservation.subtitle} ${reservation.status}'
              .toLowerCase()
              .contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
    final visible = section == '주문' ? visibleOrders : visibleReservations;

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
            labels: const ['주문', '예약'],
            selected: section,
            onChanged: (value) {
              setState(() {
                section = value;
                filter = '전체';
              });
            },
          ),
          FilterTabs(
            labels: section == '주문'
                ? const ['전체', '주문 완료', '결제 완료']
                : const ['전체', '예약 유지', '주문 전환', '예약 만료'],
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
              if (item is OwnerOrderRecord)
                DataTile(
                  icon: Icons.receipt_long_outlined,
                  title: item.title,
                  subtitle: item.subtitle,
                  badge: item.status,
                  badgeColor: item.color,
                )
              else if (item is OwnerReservationRecord)
                DataTile(
                  icon: Icons.event_available_outlined,
                  title: item.title,
                  subtitle: item.subtitle,
                  badge: item.status,
                  badgeColor: item.color,
                ),
          if (!loading && visible.isEmpty)
            const NoticeBox(color: AppColors.yellow, text: '검색 결과가 없습니다.'),
        ],
      ),
    );
  }
}

List<OwnerOrderRecord> sharedOwnerOrders = const [];
