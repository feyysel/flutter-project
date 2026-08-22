import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_profile_screen.dart';
import 'driver_ride_post_screen.dart';
import 'driver_home_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_side_menu.dart';
import '../../widgets/premium_ui.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  static const List<SideMenuItem> _menuItems = [
    SideMenuItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: "Map"),
    SideMenuItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: "Ride Post"),
    SideMenuItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: "Earnings"),
    SideMenuItem(icon: Icons.person_outline, activeIcon: Icons.person, label: "Profile"),
  ];

  Widget _menuDestination(int index) {
    switch (index) {
      case 0:
        return DriverHomeScreen();
      case 1:
        return DriverRidePostScreen();
      case 3:
        return DriverProfileScreen();
      default:
        return DriverEarningsScreen();
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Earnings",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: Builder(
          builder: (menuContext) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(menuContext).openDrawer(),
          ),
        ),
      ),
      drawer: PremiumSideMenu(
        items: _menuItems,
        currentIndex: 2,
        roleLabel: 'Driver',
        onLogout: _signOut,
        onItemTap: (index) => PremiumSideMenu.navigateAfterClose(
          context,
          _menuDestination(index),
          isCurrent: index == 2,
        ),
      ),
      body: PremiumBackground(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase
              .from('ride_history')
              .stream(primaryKey: ['id'])
              .eq('driver_id', _currentUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final rides = snapshot.data!;
            double total = 0;
            for (var ride in rides) {
              total += double.tryParse(ride['price'].toString()) ?? 0;
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.40),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("TOTAL EARNINGS",
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                      color: Colors.white.withValues(
                                          alpha: 0.75))),
                              const SizedBox(height: 6),
                              Text("$total ETB",
                                  style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.route_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 5),
                              Text("${rides.length} trips",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(left: 20, bottom: 12),
                    child: const MicroLabel("Recent payouts"),
                  ),
                ),
                Expanded(
                  child: rides.isEmpty
                      ? const EmptyState(
                          icon: Icons.payments_rounded,
                          title: "No earnings yet",
                          message:
                              "Complete rides to see your payouts here.",
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: rides.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final ride = rides[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface
                                    .withValues(alpha: 0.97),
                                borderRadius: BorderRadius.circular(22),
                                border:
                                    Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.13),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      (ride['passenger_name'] ??
                                              'P')
                                          .toString()
                                          .trim()
                                          .characters
                                          .first
                                          .toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success),
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "${ride['from']} → ${ride['to']}",
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w700,
                                                fontSize: 14.5,
                                                color: AppColors
                                                    .textPrimary)),
                                        const SizedBox(height: 4),
                                        Text(
                                            ride['passenger_name'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 12.5,
                                                color: AppColors
                                                    .textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text("+ ${ride['price']} ETB",
                                      style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15)),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
