import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_side_menu.dart';
import 'admin_users.dart';
import 'admin_rides.dart';
import 'admin_verifications.dart';
import 'admin_stats.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  static const List<SideMenuItem> _menuItems = [
    SideMenuItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: "Dashboard"),
    SideMenuItem(icon: Icons.people_outline, activeIcon: Icons.people, label: "Users"),
    SideMenuItem(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, label: "Rides"),
    SideMenuItem(icon: Icons.verified_user_outlined, activeIcon: Icons.verified_user, label: "Verify"),
  ];

  final List<Widget> _pages = [
    const AdminStatsPage(),
    const AdminUsersPage(),
    const AdminRidesPage(),
    const AdminVerificationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.admin_panel_settings,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Text("DriveOn Admin",
                      style: TextStyle(color: AppColors.textPrimary)),
                ],
              ),
              leading: Builder(
                builder: (menuContext) => IconButton(
                  icon: const Icon(Icons.menu_rounded,
                      color: AppColors.textPrimary),
                  onPressed: () => Scaffold.of(menuContext).openDrawer(),
                ),
              ),
            ),
      drawer: PremiumSideMenu(
        items: _menuItems,
        currentIndex: _selectedIndex,
        roleLabel: 'Administrator',
        onItemTap: (index) {
          Navigator.of(context).pop();
          setState(() => _selectedIndex = index);
        },
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              backgroundColor: const Color(0xFF11151F),
              indicatorColor: const Color(0xFF7C4DFF).withOpacity(0.2),
              selectedIconTheme:
                  const IconThemeData(color: Color(0xFF7C4DFF)),
              unselectedIconTheme:
                  const IconThemeData(color: Colors.grey),
              selectedLabelTextStyle: const TextStyle(
                  color: Color(0xFF7C4DFF),
                  fontWeight: FontWeight.w600),
              unselectedLabelTextStyle:
                  const TextStyle(color: Colors.grey),
              leading: Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: Color(0xFF7C4DFF), size: 28),
                    SizedBox(width: 10),
                    Text("DriveOn",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
              ),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text("Dashboard"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline),
                  selectedIcon: Icon(Icons.people),
                  label: Text("Users"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.directions_car_outlined),
                  selectedIcon: Icon(Icons.directions_car),
                  label: Text("Rides"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.verified_user_outlined),
                  selectedIcon: Icon(Icons.verified_user),
                  label: Text("Verify"),
                ),
              ],
            ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
