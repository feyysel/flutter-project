import 'package:flutter/material.dart';
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
      bottomNavigationBar: !isWide
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              backgroundColor: const Color(0xFF11151F),
              indicatorColor: const Color(0xFF7C4DFF).withOpacity(0.2),
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    label: "Dashboard"),
                NavigationDestination(
                    icon: Icon(Icons.people_outline), label: "Users"),
                NavigationDestination(
                    icon: Icon(Icons.directions_car_outlined),
                    label: "Rides"),
                NavigationDestination(
                    icon: Icon(Icons.verified_user_outlined),
                    label: "Verify"),
              ],
            )
          : null,
    );
  }
}
