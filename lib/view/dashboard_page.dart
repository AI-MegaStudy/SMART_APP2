import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
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
  final VoidCallback? onTitleTripleTap;
  final VoidCallback? onSubtitleTripleTap;

  const DashboardPage({
    super.key,
    required this.onJump,
    this.onTitleTripleTap,
    this.onSubtitleTripleTap,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _coachTapWindow = Duration(milliseconds: 850);
  final ownerRepository = OwnerRepository();
  final productRepository = ProductRepository();
  bool didLoad = false;
  int coachTapCount = 0;
  int demoTapCount = 0;
  DateTime? lastCoachTapAt;
  DateTime? lastDemoTapAt;
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
      productRepository.fetchOwnerFarms().catchError(
        (_) => <OwnerFarmRecord>[],
      ),
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

  void _handleSubtitleTap() {
    if (widget.onSubtitleTripleTap == null) return;
    final now = DateTime.now();
    final isFastTap =
        lastCoachTapAt != null &&
        now.difference(lastCoachTapAt!) < _coachTapWindow;
    coachTapCount = isFastTap ? coachTapCount + 1 : 1;
    lastCoachTapAt = now;
    if (coachTapCount < 3) return;
    coachTapCount = 0;
    debugPrint('[데모 진입][coach] 홈 서브타이틀 3탭 감지');
    widget.onSubtitleTripleTap?.call();
  }

  void _handleTitleTap() {
    if (widget.onTitleTripleTap == null) return;
    final now = DateTime.now();
    final isFastTap =
        lastDemoTapAt != null &&
        now.difference(lastDemoTapAt!) < _coachTapWindow;
    demoTapCount = isFastTap ? demoTapCount + 1 : 1;
    lastDemoTapAt = now;
    if (demoTapCount < 3) return;
    demoTapCount = 0;
    debugPrint('[데모 진입][auto] 홈 타이틀 3탭 감지');
    widget.onTitleTripleTap?.call();
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
      titleKey: DemoTargetKeys.homeGreeting,
      onTitleTap: _handleTitleTap,
      subtitle: farmName == null || farmName.isEmpty ? '내 농장' : farmName,
      subtitleKey: DemoTargetKeys.homeSubtitle,
      onSubtitleTap: _handleSubtitleTap,
      children: [
        _MlReferenceCard(onPressed: () => _open(const HarvestSlotPage())),
        const SectionHeader(title: '업무 현황'),
        GridCards(
          children: [
            MetricCard(
              key: DemoTargetKeys.dashboardQuality,
              icon: Icons.center_focus_strong_outlined,
              value: '${dashboard?.inspectionWaiting ?? 0}',
              label: '선별 대기',
              onTap: () => _open(const QualityPage()),
            ),
            MetricCard(
              key: DemoTargetKeys.dashboardProcurement,
              icon: Icons.assignment_turned_in_outlined,
              value: '${dashboard?.newProcurements ?? 0}',
              label: '신규 발주',
              onTap: () => _open(const ProcurementPage()),
            ),
            MetricCard(
              key: DemoTargetKeys.dashboardShipment,
              icon: Icons.local_shipping_outlined,
              value: '${dashboard?.readyToShip ?? 0}',
              label: '배송 준비',
              onTap: () => _open(const ShipmentPage()),
            ),
            MetricCard(
              key: DemoTargetKeys.dashboardReturn,
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
