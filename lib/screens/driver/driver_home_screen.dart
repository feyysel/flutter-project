import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'driver_profile_screen.dart';
import 'driver_ride_post_screen.dart';
import 'driver_earnings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/ride_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/premium_side_menu.dart';

class DriverHomeScreen extends StatefulWidget {
  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isOnline = true;

  final MapController mapController = MapController();
  LatLng currentLocation = const LatLng(9.5931, 41.8661);
  bool _mapReady = false;

  Timer? _locationTimer;
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  static const List<SideMenuItem> _menuItems = [
    SideMenuItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: "Map"),
    SideMenuItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: "Ride Post",
    ),
    SideMenuItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: "Earnings",
    ),
    SideMenuItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: "Profile",
    ),
  ];

  Widget _menuDestination(int index) {
    switch (index) {
      case 1:
        return DriverRidePostScreen();
      case 2:
        return DriverEarningsScreen();
      case 3:
        return DriverProfileScreen();
      default:
        return DriverHomeScreen();
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _persistLocation(LatLng position) async {
    if (_currentUserId.isEmpty) return;
    await _supabase
        .from('profiles')
        .update({'lat': position.latitude, 'lng': position.longitude})
        .eq('id', _currentUserId);
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (position != null) {
      setState(() {
        currentLocation = position;
      });
      if (_mapReady) {
        mapController.move(position, 15);
      }
      if (isOnline) {
        await _persistLocation(position);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text("Couldn't access GPS — showing default area"),
        ),
      );
    }
  }

  Stream<Map<String, dynamic>> getDriverStats() async* {
    if (_currentUserId.isEmpty) return;

    await for (final snapshot
        in _supabase
            .from('ride_history')
            .stream(primaryKey: ['id'])
            .eq('driver_id', _currentUserId)) {
      double totalEarnings = 0;
      int totalTrips = snapshot.length;

      for (var data in snapshot) {
        totalEarnings += double.tryParse(data["price"].toString()) ?? 0;
      }

      yield {"earnings": totalEarnings, "trips": totalTrips};
    }
  }

  @override
  void initState() {
    super.initState();
    listenNotifications();
    _initLocation();
    if (isOnline) {
      _startLocationUpdates();
    }
  }

  void _startLocationUpdates() {
    _stopLocationUpdates();
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!isOnline) return;
      final position = await LocationService.getCurrentPosition();
      if (position == null) return;
      await _persistLocation(position);
    });
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _stopLocationUpdates();
    super.dispose();
  }

  static const Set<String> _seenNotificationIds = <String>{};

  void listenNotifications() {
    if (_currentUserId.isEmpty) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .listen((snapshot) async {
          final fresh = snapshot
              .where(
                (n) =>
                    n['read'] == false &&
                    !_seenNotificationIds.contains(n['id']),
              )
              .toList();

          for (final n in fresh) {
            _seenNotificationIds.add(n['id']);
            if (!mounted) return;
            NotificationService.showLocal(
              title: (n['title'] ?? 'DriveOn').toString(),
              body: (n['body'] ?? '').toString(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.surfaceHigh,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                content: Text(
                  "${n['title'] ?? ''} — ${n['body'] ?? ''}",
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation,
                initialZoom: 14,
                backgroundColor: AppColors.background,
                onMapReady: () {
                  _mapReady = true;
                  mapController.move(currentLocation, 15);
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.example.ride_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation,
                      width: 54,
                      height: 54,
                      child: const MapMarker(icon: Icons.directions_car),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Builder(
                        builder: (menuContext) => GestureDetector(
                          onTap: () => Scaffold.of(menuContext).openDrawer(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_rounded,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "DriveOn",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.primaryVivid,
                        ),
                      ),
                      const Spacer(),
                      const NotificationBell(),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? AppColors.success
                                    : AppColors.danger,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isOnline
                                        ? AppColors.success
                                        : AppColors.danger,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE",
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          final newStatus = !isOnline;
                          setState(() {
                            isOnline = newStatus;
                          });

                          LatLng? position;
                          if (newStatus) {
                            position =
                                await LocationService.getCurrentPosition();
                          }

                          await _supabase
                              .from('profiles')
                              .update({
                                'is_online': newStatus,
                                if (position != null) 'lat': position.latitude,
                                if (position != null) 'lng': position.longitude,
                              })
                              .eq('id', _currentUserId);

                          final posts = await _supabase
                              .from('posts')
                              .select()
                              .eq('driver_id', _currentUserId);

                          for (var post in posts) {
                            await _supabase
                                .from('posts')
                                .update({
                                  'is_online': newStatus,
                                  if (position != null)
                                    'lat': position.latitude,
                                  if (position != null)
                                    'lng': position.longitude,
                                })
                                .eq('id', post['id']);
                          }

                          if (newStatus) {
                            _startLocationUpdates();
                          } else {
                            _stopLocationUpdates();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            isOnline ? "Go Offline" : "Go Online",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<Map<String, dynamic>>(
                    stream: getDriverStats(),
                    builder: (context, snapshot) {
                      double earnings = 0;
                      int trips = 0;
                      if (snapshot.hasData) {
                        earnings = snapshot.data!["earnings"];
                        trips = snapshot.data!["trips"];
                      }
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "TOTAL EARNINGS",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 1.6,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "$earnings ETB",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text(
                                  "TRIPS",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    letterSpacing: 1.6,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions_car_rounded,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$trips",
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: AppColors.primaryVivid,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const Spacer(),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: RideService.getRideRequests(_currentUserId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 32,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "No ride requests available",
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Waiting for passenger requests...",
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    final requests = snapshot.data!;
                    final pendingAccepted = requests
                        .where(
                          (r) =>
                              r['status'] == 'pending' ||
                              r['status'] == 'accepted',
                        )
                        .toList();

                    if (pendingAccepted.isEmpty) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 32,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "No ride requests available",
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Waiting for passenger requests...",
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    Map<String, List<Map<String, dynamic>>> groupedRequests =
                        {};
                    for (var request in pendingAccepted) {
                      final rideId = request['ride_id'];
                      if (!groupedRequests.containsKey(rideId)) {
                        groupedRequests[rideId] = [];
                      }
                      groupedRequests[rideId]!.add(request);
                    }

                    return Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: groupedRequests.entries.map((entry) {
                          final rideRequests = entry.value;
                          final firstRequest = rideRequests.first;

                          return Card(
                            color: AppColors.surface.withValues(alpha: 0.97),
                            margin: const EdgeInsets.only(bottom: 20),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: AppColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${firstRequest['from']} → ${firstRequest['to']}",
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.groups_rounded,
                                        size: 16,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Passengers (${rideRequests.length})",
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  ...rideRequests.map((request) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 15),
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF11151F),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request["passenger_name"] ?? '',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone_outlined,
                                                size: 13,
                                                color: AppColors.textMuted,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                request["passenger_phone"] ??
                                                    '',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "${request["price"]} ETB",
                                            style: const TextStyle(
                                              color: AppColors.gold,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          Column(
                                            children: [
                                              if (request["status"] ==
                                                  "pending")
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 44,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors
                                                          .danger
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                      foregroundColor:
                                                          AppColors.danger,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        side: BorderSide(
                                                          color: AppColors
                                                              .danger
                                                              .withValues(
                                                                alpha: 0.40,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      await RideService.updateRideRequest(
                                                        request['id'],
                                                        {'status': 'declined'},
                                                      );

                                                      await RideService.addNotification(
                                                        userId:
                                                            request['passenger_id'],
                                                        title: "Ride Declined",
                                                        body:
                                                            "${request['driver_name'] ?? 'The driver'} can't take this ride. Try booking another one.",
                                                      );
                                                    },
                                                    child: const Text(
                                                      "Decline",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 44,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.primary,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    await RideService.updateRideRequest(
                                                      request['id'],
                                                      {'status': 'accepted'},
                                                    );

                                                    await _supabase
                                                        .from('posts')
                                                        .update({
                                                          'available_seats':
                                                              request['available_seats'] -
                                                              1,
                                                        })
                                                        .eq(
                                                          'id',
                                                          request['ride_id'],
                                                        );

                                                    final ride = await _supabase
                                                        .from('posts')
                                                        .select()
                                                        .eq(
                                                          'id',
                                                          request['ride_id'],
                                                        )
                                                        .maybeSingle();

                                                    if (ride != null &&
                                                        (ride['available_seats'] ??
                                                                0) <=
                                                            0) {
                                                      await _supabase
                                                          .from('posts')
                                                          .update({
                                                            'is_full': true,
                                                          })
                                                          .eq(
                                                            'id',
                                                            request['ride_id'],
                                                          );
                                                    }

                                                    await RideService.addNotification(
                                                      userId:
                                                          request['passenger_id'],
                                                      title: "Ride Accepted",
                                                      body:
                                                          "Driver accepted your ride",
                                                    );
                                                  },
                                                  child: const Text("Accept"),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (request["status"] == "accepted")
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12,
                                              ),
                                              child: SizedBox(
                                                width: double.infinity,
                                                height: 44,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        AppColors.success,
                                                    foregroundColor:
                                                        AppColors.background,
                                                    elevation: 0,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            14,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    await RideService.updateRideRequest(
                                                      request['id'],
                                                      {'status': 'completed'},
                                                    );

                                                    await RideService.addRideHistory(
                                                      {
                                                        ...request,
                                                        'status': 'completed',
                                                      },
                                                    );

                                                    await RideService.addNotification(
                                                      userId:
                                                          request['passenger_id'],
                                                      title: "Ride Completed",
                                                      body:
                                                          "Your ride with ${request['driver_name'] ?? 'the driver'} is complete. Thanks for riding with DriveOn!",
                                                    );

                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        backgroundColor:
                                                            AppColors.success,
                                                        content: Text(
                                                          "Ride Completed",
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    "Complete Ride",
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: PremiumSideMenu(
        items: _menuItems,
        currentIndex: 0,
        roleLabel: 'Driver',
        onLogout: _signOut,
        onItemTap: (index) => PremiumSideMenu.navigateAfterClose(
          context,
          _menuDestination(index),
          isCurrent: index == 0,
        ),
      ),
    );
  }
}
