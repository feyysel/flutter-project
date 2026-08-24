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
import '../../services/trip_service.dart';
import 'driver_trip_screen.dart';
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
        in RideService.getRideHistory(_currentUserId, field: 'driver_id')) {
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

    RideService.getNotifications(_currentUserId).listen((snapshot) async {
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

  List<Widget> _buildRequestActions(Map<String, dynamic> request) {
    final status = (request['status'] ?? '').toString();

    switch (status) {
      case 'pending':
        return [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.danger.withValues(alpha: 0.12),
                      foregroundColor: AppColors.danger,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.40),
                        ),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await TripService.declineRequest(request);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.danger,
                            content: Text("Ride request declined"),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.danger,
                            content: Text("Could not decline: $e"),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Decline",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _onAccept(request),
                    child: const Text("Accept"),
                  ),
                ),
              ),
            ],
          ),
        ];

      case 'accepted':
        return [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.payments_outlined, size: 16, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Waiting for passenger payment…",
                    style: TextStyle(fontSize: 12.5, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ];

      case 'payment_submitted':
        return [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceHigh,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    onPressed: () => _viewReceipt(request),
                    child: const Text("View Receipt"),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _verifyPayment(request),
                    child: const Text("Accept Payment"),
                  ),
                ),
              ),
            ],
          ),
        ];

      case 'confirmed':
      case 'picked_up':
      case 'dropped_off':
        return [_buildVerifiedBadge(status)];

      default:
        return [];
    }
  }

  Widget _buildVerifiedBadge(String status) {
    final Map<String, List<dynamic>> styles = {
      'confirmed': [
        Icons.verified_rounded,
        "Payment verified — seat reserved",
        AppColors.success
      ],
      'picked_up': [
        Icons.directions_car_rounded,
        "Passenger on board",
        AppColors.accent
      ],
      'dropped_off': [
        Icons.flag_rounded,
        "Dropped off at destination",
        AppColors.gold
      ],
    };
    final style = styles[status]!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (style[2] as Color).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (style[2] as Color).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(style[0] as IconData, size: 16, color: style[2] as Color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              style[1] as String,
              style: TextStyle(fontSize: 12.5, color: style[2] as Color),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept(Map<String, dynamic> request) async {
    try {
      var profile = await TripService.getProfile(_currentUserId);

      if (!TripService.hasCompleteBankDetails(profile)) {
        final saved = await _promptBankDetails(profile);
        if (saved != true) return;
        profile = await TripService.getProfile(_currentUserId);
        if (!TripService.hasCompleteBankDetails(profile)) return;
      }

      await TripService.acceptRequest(request);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
              "Ride accepted — your bank details were sent to the passenger"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text("Could not accept ride: $e"),
        ),
      );
    }
  }

  Future<bool?> _promptBankDetails(Map<String, dynamic>? profile) async {
    final bankController =
        TextEditingController(text: (profile?['bank_name'] ?? '').toString());
    final holderController = TextEditingController(
        text: (profile?['bank_account_holder'] ?? '').toString());
    final accountController = TextEditingController(
        text: (profile?['bank_account_number'] ?? '').toString());

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Payout Account"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Passengers need your account details to pay you.",
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bankController,
                decoration: const InputDecoration(
                    labelText: "Bank name (e.g. CBE, Telebirr)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderController,
                decoration:
                    const InputDecoration(labelText: "Account holder name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accountController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: "Account number"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (bankController.text.trim().isEmpty ||
                  holderController.text.trim().isEmpty ||
                  accountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.danger,
                    content: Text("Fill all payout fields"),
                  ),
                );
                return;
              }
              try {
                await TripService.saveBankDetails(
                  userId: _currentUserId,
                  bankName: bankController.text,
                  accountHolder: holderController.text,
                  accountNumber: accountController.text,
                );
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext, true);
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.danger,
                      content: Text("Could not save details: $e"),
                    ),
                  );
                }
              }
            },
            child: const Text("Save & Accept Ride"),
          ),
        ],
      ),
    );
  }

  void _viewReceipt(Map<String, dynamic> request) {
    final receiptUrl = (request['payment_receipt_url'] ?? '').toString();
    final txn = (request['payment_txn'] ?? '').toString();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Payment Receipt",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: receiptUrl.isEmpty
                    ? Container(
                        height: 180,
                        width: double.infinity,
                        color: AppColors.surfaceHigh,
                        alignment: Alignment.center,
                        child:
                            const Text("No image", style: TextStyle(color: AppColors.textMuted)),
                      )
                    : InteractiveViewer(
                        maxScale: 4,
                        child: Image.network(receiptUrl),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                txn.isEmpty
                    ? "Transaction number: not provided"
                    : "Transaction number: $txn",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPayment(Map<String, dynamic> request) async {
    bool ok = false;
    String? error;
    try {
      ok = await TripService.verifyPayment(request);
    } catch (e) {
      error = e.toString();
    }
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text("Payment accepted — seat reserved and ticket generated"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(
              error ?? "Could not verify payment — no seats left or already processed"),
        ),
      );
    }
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
                    final data = snapshot.data ?? const [];

                    final activeRequests = data
                        .where(
                          (r) =>
                              r['status'] != 'declined' &&
                              r['status'] != 'cancelled' &&
                              r['status'] != 'completed',
                        )
                        .toList();

                    final manageable = data
                        .where(
                          (r) => const [
                                'confirmed',
                                'picked_up',
                                'dropped_off',
                              ].contains(r['status']),
                        )
                        .toList();

                    if (!snapshot.hasData || activeRequests.isEmpty) {
                      return Expanded(
                        child: Container(
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
                        ),
                      );
                    }

                    Map<String, List<Map<String, dynamic>>> groupedRequests =
                        {};
                    for (var request in activeRequests) {
                      final rideId = request['ride_id'];
                      if (!groupedRequests.containsKey(rideId)) {
                        groupedRequests[rideId] = [];
                      }
                      groupedRequests[rideId]!.add(request);
                    }

                    return Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              children: groupedRequests.entries.map((entry) {
                                final rideRequests = entry.value;
                                final firstRequest = rideRequests.first;

                                return Card(
                                  color:
                                      AppColors.surface.withValues(alpha: 0.97),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side:
                                        BorderSide(color: AppColors.border),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            margin: const EdgeInsets.only(
                                                bottom: 15),
                                            padding:
                                                const EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              color:
                                                  const Color(0xFF11151F),
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  request[
                                                          "passenger_name"] ??
                                                      '',
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 17,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone_outlined,
                                                      size: 13,
                                                      color:
                                                          AppColors.textMuted,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      request[
                                                              "passenger_phone"] ??
                                                          '',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
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
                                                    fontWeight:
                                                        FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 15),
                                                ..._buildRequestActions(
                                                    request),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if (manageable.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  shadowColor:
                                      AppColors.primary.withValues(alpha: 0.5),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DriverTripScreen(
                                          rideId:
                                              manageable.first['ride_id']
                                                  .toString()),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.route_rounded,
                                    size: 20),
                                label: Text(
                                  "Manage Trip (${manageable.length} verified "
                                  "passenger${manageable.length == 1 ? '' : 's'})",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
