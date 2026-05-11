import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_demo_manager.dart';
import 'package:smart_app/view/dashboard_page.dart';
import 'package:smart_app/view/menu_page.dart';
import 'package:smart_app/view/profile_page.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const _demoTapWindow = Duration(milliseconds: 850);
  int selectedIndex = 1;
  int demoTapCount = 0;
  DateTime? lastDemoTapAt;
  OwnerDemoManager? demoManager;

  late final pages = <_ShellPage>[
    const _ShellPage(
      label: '메뉴',
      icon: Icons.menu_rounded,
      selectedIcon: Icons.menu_rounded,
      child: MenuPage(),
    ),
    _ShellPage(
      label: '홈',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      child: DashboardPage(onJump: _selectTab),
    ),
    const _ShellPage(
      label: '마이',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      child: ProfilePage(),
    ),
  ];

  void _selectTab(int index) {
    setState(() {
      selectedIndex = index.clamp(0, pages.length - 1).toInt();
    });
  }

  void _handleHiddenDemoTap(PointerDownEvent event) {
    if (selectedIndex != 1) return;
    final topAreaHeight = MediaQuery.paddingOf(context).top + 128;
    if (event.position.dy > topAreaHeight) return;

    final now = DateTime.now();
    final isFastTap =
        lastDemoTapAt != null &&
        now.difference(lastDemoTapAt!) < _demoTapWindow;
    demoTapCount = isFastTap ? demoTapCount + 1 : 1;
    lastDemoTapAt = now;

    if (demoTapCount >= 3) {
      demoTapCount = 0;
      demoManager?.stop();
      demoManager = OwnerDemoManager(context: context, selectTab: _selectTab);
      demoManager!.start();
    }
  }

  @override
  void dispose() {
    demoManager?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = pages[selectedIndex];

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleHiddenDemoTap,
      child: Scaffold(
        body: current.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: _selectTab,
          destinations: [
            for (var index = 0; index < pages.length; index++)
              NavigationDestination(
                icon: Icon(
                  pages[index].icon,
                  key: index == 0
                      ? DemoTargetKeys.navMenu
                      : index == 2
                      ? DemoTargetKeys.navProfile
                      : null,
                ),
                selectedIcon: Icon(pages[index].selectedIcon),
                label: pages[index].label,
              ),
          ],
        ),
      ),
    );
  }
}

class _ShellPage {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget child;

  const _ShellPage({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.child,
  });
}
