import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ride_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Trip History",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: PremiumBackground(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: RideService.getRideHistory(userId, field: 'driver_id'),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final rides = snapshot.data!;

            if (rides.isEmpty) {
              return const EmptyState(
                icon: Icons.route_rounded,
                title: "No completed trips",
                message: "Trips you complete will appear here.",
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: rides.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final ride = rides[index];
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
                          const StatusChip("Completed",
                              color: AppColors.success),
                          const Spacer(),
                          Text("+ ${ride['price']} ETB",
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      RoutePoints(
                        from: ride['from']?.toString() ?? '',
                        to: ride['to']?.toString() ?? '',
                      ),
                      if ((ride['passenger_name'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 15, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text("${ride['passenger_name']}",
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary)),
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
}
