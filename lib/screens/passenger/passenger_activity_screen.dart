import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'passenger_profile_screen.dart';
import 'passenger_home_screen.dart';
import '../../services/ride_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_side_menu.dart';
import '../../widgets/premium_ui.dart';

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() =>
      _PassengerActivityScreenState();
}

class _PassengerActivityScreenState extends State<PassengerActivityScreen> {
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  static const List<SideMenuItem> _menuItems = [
    SideMenuItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: "Home"),
    SideMenuItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: "Activity"),
    SideMenuItem(icon: Icons.person_outline, activeIcon: Icons.person, label: "Profile"),
  ];

  Widget _menuDestination(int index) {
    switch (index) {
      case 0:
        return PassengerHomeScreen();
      case 2:
        return PassengerProfileScreen();
      default:
        return PassengerActivityScreen();
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Color _statusColor(String status) {
    switch (status) {
      case "accepted":
        return AppColors.success;
      case "completed":
        return AppColors.primaryVivid;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Activity",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        currentIndex: 1,
        roleLabel: 'Passenger',
        onLogout: _signOut,
        onItemTap: (index) => PremiumSideMenu.navigateAfterClose(
          context,
          _menuDestination(index),
          isCurrent: index == 1,
        ),
      ),
      body: PremiumBackground(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _supabase
              .from('ride_requests')
              .stream(primaryKey: ['id'])
              .eq('passenger_id', _currentUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: "No ride activity yet",
                message: "Book your first intercity trip and it will show up here.",
              );
            }

            final rides = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: rides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final ride = rides[index];
                final statusColor =
                    _statusColor(ride['status'].toString());

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusChip(ride['status'].toString(),
                              color: statusColor),
                          const Spacer(),
                          Text("${ride['price']} ETB",
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.gold)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      RoutePoints(
                        from: ride['from']?.toString() ?? '',
                        to: ride['to']?.toString() ?? '',
                      ),
                      if (ride['status'] == "pending") ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.hourglass_top_rounded,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                  "Waiting for driver acceptance…",
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _CancelButton(
                            onRequestCancelled: () =>
                                RideService.deleteRideRequest(ride['id'])),
                      ],
                      if (ride['status'] == "accepted") ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 16, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text("Driver accepted your ride",
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const MicroLabel("Your driver",
                                  color: AppColors.accent),
                              const SizedBox(height: 10),
                              _detailRow(Icons.person_outline_rounded,
                                  ride['driver_name']),
                              const SizedBox(height: 8),
                              _detailRow(Icons.phone_outlined,
                                  ride['driver_phone']),
                              const SizedBox(height: 8),
                              _detailRow(Icons.badge_outlined,
                                  ride['driver_plate']),
                            ],
                          ),
                        ),
                      ],
                      if (ride['status'] == "completed") ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                size: 16, color: AppColors.primaryVivid),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text("Ride completed successfully",
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryVivid)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, dynamic value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            (value == null || value.toString().isEmpty)
                ? "—"
                : value.toString(),
            style: const TextStyle(
                fontSize: 13.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onRequestCancelled});

  final Future<void> Function() onRequestCancelled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await onRequestCancelled();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: AppColors.danger,
              content: Text("Ride request cancelled")),
        );
      },
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.45)),
          color: AppColors.danger.withValues(alpha: 0.08),
        ),
        child: const Text(
          "Cancel Request",
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.danger),
        ),
      ),
    );
  }
}
