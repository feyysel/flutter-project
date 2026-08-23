import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'ride_list_screen.dart';
import 'passenger_profile_screen.dart';
import 'passenger_activity_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/premium_side_menu.dart';
import '../../widgets/premium_ui.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final MapController mapController = MapController();
  LatLng currentLocation = LatLng(9.5931, 41.8661);
  bool _mapReady = false;
  String destination = "";
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  Stream<List<Map<String, dynamic>>> get _onlineDriversStream => _supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('is_online', true);

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
      case 1:
        return PassengerActivityScreen();
      case 2:
        return PassengerProfileScreen();
      default:
        return PassengerHomeScreen();
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void initState() {
    super.initState();
    listenNotifications();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (position != null) {
      setState(() => currentLocation = position);
      if (_mapReady) {
        mapController.move(position, 15);
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

  static const Set<String> _seenNotificationIds = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: PremiumSideMenu(
        items: _menuItems,
        currentIndex: 0,
        roleLabel: 'Passenger',
        onLogout: _signOut,
        onItemTap: (index) => PremiumSideMenu.navigateAfterClose(
          context,
          _menuDestination(index),
          isCurrent: index == 0,
        ),
      ),
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
                      child: const MapMarker(),
                    ),
                  ],
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _onlineDriversStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final markers = <Marker>[];
                    for (final data in snapshot.data!) {
                      final lat = data["lat"];
                      final lng = data["lng"];
                      if (lat is num && lng is num) {
                        markers.add(
                          Marker(
                            point: LatLng(lat.toDouble(), lng.toDouble()),
                            width: 44,
                            height: 44,
                            child: const MapMarker(icon: Icons.directions_car),
                          ),
                        );
                      }
                    }
                    if (markers.isEmpty) return const SizedBox.shrink();
                    return MarkerLayer(markers: markers);
                  },
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

          // Ambient glow accents over the map edges.
          const Positioned(
            top: -120,
            right: -100,
            child: _Glow(size: 320, color: Color(0x477C4DFF)),
          ),
          const Positioned(
            bottom: -60,
            left: -120,
            child: _Glow(size: 340, color: Color(0x4D6D28D9)),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildTopBar(),
                  const Spacer(),
                  _buildBookingCard(),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ),

          Positioned(right: 20, bottom: 132, child: _buildRecenterButton()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Builder(
          builder: (menuContext) => GestureDetector(
            onTap: () => Scaffold.of(menuContext).openDrawer(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          "DriveOn",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const NotificationBell(),
        const SizedBox(width: 12),
        _buildOnlineDriversChip(),
      ],
    );
  }

  Widget _buildOnlineDriversChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulseDot(),
          const SizedBox(width: 7),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _onlineDriversStream,
            builder: (context, snapshot) {
              var count = 0;
              if (snapshot.hasData) {
                count = snapshot.data!
                    .where((d) => d['lat'] is num && d['lng'] is num)
                    .length;
              }
              return Text(
                "$count online",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, SlideUpRoute(page: RideListScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MicroLabel('Plan your ride', color: AppColors.accent),
                  const SizedBox(height: 5),
                  Text(
                    destination.isEmpty ? "Where are you going?" : destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecenterButton() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => mapController.move(currentLocation, 15),
          child: const Icon(
            Icons.my_location_rounded,
            color: AppColors.accent,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Soft radial glow blob used behind the map overlays.
class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Pulsing green status dot for the live drivers chip.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _opacity = Tween(
      begin: 0.35,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppColors.success, blurRadius: 6, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
