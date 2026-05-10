import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_app/view/harvest_slot_page.dart';
import 'package:smart_app/view/procurement_page.dart';
import 'package:smart_app/view/quality_page.dart';
import 'package:smart_app/view/return_page.dart';
import 'package:smart_app/view/shipment_page.dart';
import 'package:smart_app/widgets/owner_widgets.dart';
import 'package:smart_app/vm/dashboard_viewmodel.dart';

class DashboardPage extends StatefulWidget {
  final ValueChanged<int> onJump;

  const DashboardPage({super.key, required this.onJump});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool didLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (didLoad) return;
    didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
    });
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardViewModel>().dashboard;

    return AppScaffold(
      title: '안녕하세요, 김하늘 점주님',
      subtitle: '충주 햇살농원',
      children: [
        _MlReferenceCard(onPressed: () => _open(const HarvestSlotPage())),
        const SectionHeader(title: '업무 현황'),
        GridCards(
          children: [
            MetricCard(
              icon: Icons.center_focus_strong_outlined,
              value: '${dashboard?.inspectionWaiting ?? 7}',
              label: '선별 대기',
              onTap: () => _open(const QualityPage()),
            ),
            MetricCard(
              icon: Icons.assignment_turned_in_outlined,
              value: '${dashboard?.newProcurements ?? 4}',
              label: '신규 발주',
              onTap: () => _open(const ProcurementPage()),
            ),
            MetricCard(
              icon: Icons.local_shipping_outlined,
              value: '${dashboard?.readyToShip ?? 3}',
              label: '배송 준비',
              onTap: () => _open(const ShipmentPage()),
            ),
            MetricCard(
              icon: Icons.keyboard_return_outlined,
              value: '2',
              label: '반품 요청',
              onTap: () => _open(const ReturnPage()),
            ),
          ],
        ),
      ],
    );
  }
}

class _MlReferenceCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _MlReferenceCard({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DataTile(
      icon: Icons.auto_graph_outlined,
      title: '상품 수확 예측',
      subtitle: 'ML 참고',
      badge: '확인',
      badgeColor: const Color(0xffDFF4E8),
      onTap: onPressed,
      showChevron: true,
    );
  }
}
