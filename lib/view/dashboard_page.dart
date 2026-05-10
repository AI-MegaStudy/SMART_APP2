import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_app/model/owner_profile.dart';
import 'package:smart_app/model/product_record.dart';
import 'package:smart_app/repositories/owner_repository.dart';
import 'package:smart_app/repositories/product_repository.dart';
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
  final ownerRepository = OwnerRepository();
  final productRepository = ProductRepository();
  bool didLoad = false;
  OwnerProfile? owner;
  OwnerFarmRecord? farm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (didLoad) return;
    didLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
      _loadHeader();
    });
  }

  Future<void> _loadHeader() async {
    final results = await Future.wait<Object?>([
      _fetchOwnerProfile(),
      productRepository.fetchOwnerFarms().catchError((_) => <OwnerFarmRecord>[]),
    ]);
    if (!mounted) return;
    final farms = results[1] as List<OwnerFarmRecord>;
    setState(() {
      owner = results[0] as OwnerProfile?;
      farm = farms.isEmpty ? null : farms.first;
    });
  }

  Future<OwnerProfile?> _fetchOwnerProfile() async {
    try {
      return await ownerRepository.fetchProfile();
    } catch (_) {
      return null;
    }
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardViewModel>().dashboard;
    final ownerName = owner?.ownerName.trim();
    final farmName = farm?.farmName.trim();

    return AppScaffold(
      title: ownerName == null || ownerName.isEmpty
          ? '안녕하세요'
          : '안녕하세요, $ownerName 점주님',
      subtitle: farmName == null || farmName.isEmpty ? '내 농장' : farmName,
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
              value: '${dashboard?.returnRequests ?? 0}',
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
