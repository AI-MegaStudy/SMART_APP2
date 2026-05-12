import 'package:flutter/material.dart';
import 'package:smart_app/demo/owner_coach_tour_manager.dart';
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
  int selectedIndex = 1;
  OwnerDemoManager? demoManager;
  OwnerCoachTourManager? coachTourManager;

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
      child: DashboardPage(
        onJump: _selectTab,
        onSubtitleTripleTap: _startCoachTour,
      ),
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

  // ignore: unused_element
  void _startAutoDemo() {
    if (selectedIndex != 1) return;
    coachTourManager?.stop();
    demoManager?.stop();
    demoManager = OwnerDemoManager(context: context, selectTab: _selectTab);
    demoManager!.start();
  }

  void _startCoachTour() {
    if (selectedIndex != 1) return;
    demoManager?.stop();
    coachTourManager?.stop();
    coachTourManager = OwnerCoachTourManager(
      context: context,
      selectTab: _selectTab,
    );
    coachTourManager!.start();
  }

  @override
  void dispose() {
    demoManager?.stop();
    coachTourManager?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = pages[selectedIndex];

    return Scaffold(
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
