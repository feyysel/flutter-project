import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ride_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  void showRideConfirmation(Map<String, dynamic> posts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF161C33), Color(0xFF0B0E1E)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                "Confirm your ride",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              RoutePoints(
                from: posts['from'] ?? '',
                to: posts['to'] ?? '',
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((posts['pickup_location'] ?? '').toString().isNotEmpty ||
                  (posts['drop_location'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        size: 17,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          [
                            if ((posts['pickup_location'] ?? '')
                                .toString()
                                .isNotEmpty)
                              "Pick up: ${posts['pickup_location']}",
                            if ((posts['drop_location'] ?? '')
                                .toString()
                                .isNotEmpty)
                              "Drop: ${posts['drop_location']}",
                          ].join("   •   "),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const GradientIconTile(
                      icon: Icons.directions_car_rounded,
                      size: 50,
                      iconSize: 26,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            posts['vehicle_model'] ?? "Economy",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${posts['driver_name'] ?? 'Driver'} • ${posts['time'] ?? 'Now'} • ${posts['seats'] ?? '4'} seats",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${posts['price']} ETB",
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          "Est. Price",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PremiumSheetButton(
                label: "Confirm Ride",
                onPressed: () async {
                  Navigator.pop(context);
                  await bookRide(
                    rideId: posts['id'],
                    driverId: posts['driver_id'],
                    rideData: posts,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> bookRide({
    required String rideId,
    required String driverId,
    required Map<String, dynamic> rideData,
  }) async {
    if (_currentUserId.isEmpty) return;

    final passengerDoc = await _supabase
        .from('profiles')
        .select()
        .eq('id', _currentUserId)
        .maybeSingle();

    final driverDoc = await _supabase
        .from('profiles')
        .select()
        .eq('id', driverId)
        .maybeSingle();

    await RideService.addRideRequest({
      'driver_name': driverDoc?["name"],
      'driver_phone': driverDoc?["phone"],
      'driver_plate': driverDoc?["plate_number"],
      'passenger_phone': passengerDoc?["phone"],
      'ride_id': rideId,
      'driver_id': driverId,
      'passenger_id': _currentUserId,
      'passenger_name': passengerDoc?["name"],
      'from': rideData["from"],
      'to': rideData["to"],
      'price': rideData["price"],
      'status': 'pending',
    });

    await RideService.addNotification(
      userId: driverId,
      title: "New Ride Request",
      body: "${passengerDoc?["name"]} requested a ride",
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        content: Text("Ride request sent"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SheetPage(
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const MicroLabel(
                              'Plan your ride',
                              color: AppColors.accent,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Choose your ride",
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GlassCircleButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search destination...",
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = "");
                              },
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: RideService.getRides(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const EmptyState(
                          icon: Icons.directions_car_rounded,
                          title: "No rides available",
                          message:
                              "Check back soon — drivers are posting new intercity trips.",
                        );
                      }

                      final rides = snapshot.data!;
                      final filteredRides = rides.where((posts) {
                        final from = posts['from'].toString().toLowerCase();
                        final to = posts['to'].toString().toLowerCase();
                        return from.contains(searchQuery) ||
                            to.contains(searchQuery);
                      }).toList();

                      if (filteredRides.isEmpty) {
                        return const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: "No matching rides",
                          message: "Try a different city or clear your search.",
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: filteredRides.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => _RideCard(
                          posts: filteredRides[index],
                          onBook: () =>
                              showRideConfirmation(filteredRides[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.posts, required this.onBook});

  final Map<String, dynamic> posts;
  final VoidCallback onBook;

  bool get _isOnline => posts['is_online'] == true;
  int get _availableSeats => (posts['available_seats'] ?? 0) as int;
  bool get _isFull => _availableSeats == 0;

  @override
  Widget build(BuildContext context) {
    final canBook = _isOnline && !_isFull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: canBook
              ? AppColors.primary.withValues(alpha: 0.30)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip(
                      _isOnline ? "Online" : "Offline",
                      color: _isOnline
                          ? AppColors.success
                          : AppColors.textMuted,
                    ),
                    if (_isFull) ...[
                      const SizedBox(width: 8),
                      const StatusChip("Full", color: AppColors.danger),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${posts['from']} → ${posts['to']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        posts['time'] ?? 'Now',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if ((posts['pickup_location'] ?? '')
                            .toString()
                            .isNotEmpty ||
                        (posts['drop_location'] ?? '').toString().isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: StatusChip("Stops", color: AppColors.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        posts['driver_name'] ?? "Driver",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.event_seat_rounded,
                      size: 15,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${posts['available_seats'] ?? 0}/${posts['total_seats'] ?? posts['seats'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${posts['price']} ETB",
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: canBook ? onBook : null,
                child: Container(
                  width: 92,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: canBook ? AppGradients.primary : null,
                    color: canBook ? null : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: canBook
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    "Book",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: canBook ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-width gradient pill button used inside sheets.
class PremiumSheetButton extends StatelessWidget {
  const PremiumSheetButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
