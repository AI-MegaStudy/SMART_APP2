import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final current = pages[selectedIndex];

    return Scaffold(
      body: current.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          for (final page in pages)
            NavigationDestination(
              icon: Icon(page.icon),
              selectedIcon: Icon(page.selectedIcon),
              label: page.label,
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
