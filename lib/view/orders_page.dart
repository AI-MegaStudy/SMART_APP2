import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/model/owner_order_record.dart';
import 'package:smart_app/repositories/owner_workflow_repository.dart';
import 'package:smart_app/util/app_colors.dart';
import 'package:smart_app/widgets/owner_widgets.dart';

class OrdersPage extends StatefulWidget {
  final bool demoMode;
  final bool demoAutoSwitchReservations;
  final String? demoInitialSection;
  final ValueListenable<String>? demoSectionListenable;

  const OrdersPage({
    super.key,
    this.demoMode = false,
    this.demoAutoSwitchReservations = true,
    this.demoInitialSection,
    this.demoSectionListenable,
  });

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
    widget.demoSectionListenable?.addListener(_handleDemoSectionChanged);
    _loadOrders();
  }

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.demoSectionListenable != widget.demoSectionListenable) {
      oldWidget.demoSectionListenable?.removeListener(
        _handleDemoSectionChanged,
      );
      widget.demoSectionListenable?.addListener(_handleDemoSectionChanged);
    }
  }

  @override
  void dispose() {
    widget.demoSectionListenable?.removeListener(_handleDemoSectionChanged);
    searchController.dispose();
    super.dispose();
  }

  void _handleDemoSectionChanged() {
    final next = widget.demoSectionListenable?.value;
    if (next != '주문' && next != '예약') return;
    setState(() {
      section = next!;
      filter = section == '주문' ? '결제 완료' : '전체';
    });
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
      if (widget.demoMode) {
        section = widget.demoInitialSection ?? '주문';
        filter = section == '주문' ? '결제 완료' : '전체';
      }
      loading = false;
    });
    if (widget.demoMode && widget.demoAutoSwitchReservations) {
      _scheduleReservationDemo();
    }
  }

  void _scheduleReservationDemo() {
    Future<void>.delayed(const Duration(milliseconds: 9300), () {
      if (!mounted) return;
      setState(() {
        section = '예약';
        filter = '전체';
      });
    });
  }

  Key? _orderKey(List<Object> visible, int index) {
    final item = visible[index];
    if (item is! OwnerOrderRecord || item.status != '결제 완료') return null;
    final isFirstPaid = !visible
        .take(index)
        .whereType<OwnerOrderRecord>()
        .any((order) => order.status == '결제 완료');
    return isFirstPaid ? DemoTargetKeys.ordersPaid : null;
  }

  Key? _reservationKey(List<Object> visible, int index) {
    final item = visible[index];
    if (item is! OwnerReservationRecord) return null;
    if (item.status == '예약 유지') {
      final isFirstKeep = !visible
          .take(index)
          .whereType<OwnerReservationRecord>()
          .any((reservation) => reservation.status == '예약 유지');
      return isFirstKeep ? DemoTargetKeys.reservationKeep : null;
    }
    if (item.status == '주문 전환') {
      final isFirstConverted = !visible
          .take(index)
          .whereType<OwnerReservationRecord>()
          .any((reservation) => reservation.status == '주문 전환');
      return isFirstConverted ? DemoTargetKeys.reservationConverted : null;
    }
    return null;
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
            key: section == '주문'
                ? DemoTargetKeys.ordersSection
                : DemoTargetKeys.reservationsSection,
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
            for (var index = 0; index < visible.length; index++)
              if (visible[index] is OwnerOrderRecord)
                DataTile(
                  key: _orderKey(visible, index),
                  icon: Icons.receipt_long_outlined,
                  title: (visible[index] as OwnerOrderRecord).title,
                  subtitle: (visible[index] as OwnerOrderRecord).subtitle,
                  badge: (visible[index] as OwnerOrderRecord).status,
                  badgeColor: (visible[index] as OwnerOrderRecord).color,
                )
              else if (visible[index] is OwnerReservationRecord)
                DataTile(
                  key: _reservationKey(visible, index),
                  icon: Icons.event_available_outlined,
                  title: (visible[index] as OwnerReservationRecord).title,
                  subtitle: (visible[index] as OwnerReservationRecord).subtitle,
                  badge: (visible[index] as OwnerReservationRecord).status,
                  badgeColor: (visible[index] as OwnerReservationRecord).color,
                ),
          if (!loading && visible.isEmpty)
            const NoticeBox(color: AppColors.yellow, text: '검색 결과가 없습니다.'),
        ],
      ),
    );
  }
}

List<OwnerOrderRecord> sharedOwnerOrders = const [];
