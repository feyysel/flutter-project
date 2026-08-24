import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'passenger_profile_screen.dart';
import 'passenger_home_screen.dart';
import 'payment_screen.dart';
import 'ticket_screen.dart';
import 'passenger_track_screen.dart';
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
    SideMenuItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: "Home",
    ),
    SideMenuItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      label: "Activity",
    ),
    SideMenuItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: "Profile",
    ),
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
      case "confirmed":
      case "picked_up":
        return AppColors.success;
      case "dropped_off":
      case "completed":
        return AppColors.gold;
      case "declined":
        return AppColors.danger;
      case "payment_submitted":
        return AppColors.warning;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case "pending":
        return "Pending";
      case "accepted":
        return "Accepted";
      case "payment_submitted":
        return "Verifying payment";
      case "confirmed":
        return "Seat reserved";
      case "picked_up":
        return "On board";
      case "dropped_off":
        return "Arrived";
      case "declined":
        return "Declined";
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Activity",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
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
          stream: RideService.getPassengerRequests(_currentUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allRides = snapshot.data!;
            allRides.sort((a, b) => (b['created_at'] ?? '').toString().compareTo(
                (a['created_at'] ?? '').toString()));

            final rides = allRides
                .where((r) => (r['status'] ?? '').toString() != 'completed')
                .toList();

            if (rides.isEmpty) {
              return const EmptyState(
                icon: Icons.receipt_long_rounded,
                title: "No ride activity yet",
                message:
                    "Book your first intercity trip and it will show up here.",
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: rides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _activityCard(context, rides[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _activityCard(BuildContext context, Map<String, dynamic> ride) {
    final status = ride['status'].toString();
    final statusColor = _statusColor(status);

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
              StatusChip(_statusLabel(status), color: statusColor),
              if ((ride['ticket_code'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                StatusChip("Ticketed", color: AppColors.accent),
              ],
              const Spacer(),
              Text(
                "${ride['price']} ETB",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          RoutePoints(
            from: ride['from']?.toString() ?? '',
            to: ride['to']?.toString() ?? '',
          ),

          ..._statusBody(ride, status),

          if (_showDriverCard(status)) ...[
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
                  const MicroLabel("Your driver", color: AppColors.accent),
                  const SizedBox(height: 10),
                  _detailRow(Icons.person_outline_rounded, ride['driver_name']),
                  const SizedBox(height: 8),
                  _detailRow(Icons.phone_outlined, ride['driver_phone']),
                  const SizedBox(height: 8),
                  _detailRow(Icons.badge_outlined, ride['driver_plate']),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _showDriverCard(String status) {
    return [
      "accepted",
      "payment_submitted",
      "confirmed",
      "picked_up",
      "dropped_off",
    ].contains(status);
  }

  List<Widget> _statusBody(Map<String, dynamic> ride, String status) {
    switch (status) {
      case "pending":
        return [
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.warning),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Waiting for driver acceptance…",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _CancelButton(
            onRequestCancelled: () async {
              await RideService.deleteRideRequest(ride['id']);
              if ((ride['driver_id'] ?? '').toString().isNotEmpty) {
                await RideService.addNotification(
                  userId: ride['driver_id'],
                  title: "Ride Request Cancelled",
                  body:
                      "A passenger cancelled their request for ${ride['from']} → ${ride['to']}.",
                );
              }
            },
          ),
        ];

      case "declined":
        return [
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.cancel_rounded, size: 16, color: AppColors.danger),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "The driver couldn't take this ride. Try booking another one.",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        ];

      case "accepted":
        return _acceptedBody(ride);

      case "payment_submitted":
        return [
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.pending_actions_rounded,
                  size: 16, color: AppColors.warning),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Receipt sent — waiting for driver verification…",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            (ride['payment_txn'] ?? '').toString().isEmpty
                ? "No transaction number attached"
                : "Transaction No: ${ride['payment_txn']}",
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ];

      case "confirmed":
        return [
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Payment accepted — your seat is reserved!",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _actionTile("View Ticket", Icons.confirmation_number_rounded,
                  () => _openTicket(ride))),
              const SizedBox(width: 10),
              Expanded(child: _actionTile("Track Driver", Icons.radar_rounded,
                  () => _openTracking(ride))),
            ],
          ),
        ];

      case "picked_up":
        return [
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: AppColors.primaryVivid),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "You're on board — follow your route below",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryVivid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _actionTile("Ticket", Icons.confirmation_number_rounded,
                  () => _openTicket(ride))),
              const SizedBox(width: 10),
              Expanded(child: _actionTile("Route Map", Icons.map_rounded,
                  () => _openTracking(ride))),
            ],
          ),
        ];

      case "dropped_off":
        return [
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.celebration_rounded, size: 18, color: AppColors.success),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    "Trip completed successfully. Keep your ticket as evidence.",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _actionTile("View Ticket (Evidence)", Icons.workspace_premium_rounded,
              () => _openTicket(ride)),
        ];

      default:
        return [];
    }
  }

  List<Widget> _acceptedBody(Map<String, dynamic> ride) {
    final bank = (ride['pay_bank_name'] ?? '').toString();
    final holder = (ride['pay_bank_holder'] ?? '').toString();
    final account = (ride['pay_account_number'] ?? '').toString();

    return [
      const SizedBox(height: 14),
      const Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              "Driver accepted your ride",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MicroLabel("Pay externally using", color: AppColors.gold),
            const SizedBox(height: 10),
            _detailRow(Icons.account_balance_rounded, bank.isEmpty ? "Bank" : bank),
            const SizedBox(height: 7),
            _detailRow(Icons.person_outline_rounded,
                holder.isEmpty ? "Account holder" : holder),
            const SizedBox(height: 7),
            _detailRow(Icons.numbers_rounded,
                account.isEmpty ? "Account number" : account),
            const SizedBox(height: 10),
            Text(
              "Send ${ride['price']} ETB, then attach your receipt screenshot and transaction number (optional).",
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _actionTile("Pay & Upload Receipt", Icons.upload_file_rounded,
          () => _openPayment(ride), highlight: true),
    ];
  }

  void _openPayment(Map<String, dynamic> ride) {
    Navigator.push(
      context,
      SlideUpRoute(page: PaymentScreen(request: ride)),
    );
  }

  void _openTicket(Map<String, dynamic> ride) {
    Navigator.push(
      context,
      SlideUpRoute(page: TicketScreen(request: ride)),
    );
  }

  void _openTracking(Map<String, dynamic> ride) {
    Navigator.push(
      context,
      SlideUpRoute(page: PassengerTrackScreen(request: ride)),
    );
  }

  Widget _actionTile(String label, IconData icon, VoidCallback onTap,
      {bool highlight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: highlight ? AppGradients.primary : null,
          color: highlight ? null : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
          border: highlight
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4))
              : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 17,
                color: highlight ? Colors.white : AppColors.accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: highlight ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
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
              fontSize: 13.5,
              color: AppColors.textSecondary,
            ),
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
            content: Text("Ride request cancelled"),
          ),
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
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
