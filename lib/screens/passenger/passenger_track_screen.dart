import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/city_locations.dart';
import '../../services/live_query.dart';
import '../../services/location_service.dart';
import '../../services/trip_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';
import 'ticket_screen.dart';

class PassengerTrackScreen extends StatefulWidget {
  const PassengerTrackScreen({super.key, required this.request});

  final Map<String, dynamic> request;

  @override
  State<PassengerTrackScreen> createState() => _PassengerTrackScreenState();
}

class _PassengerTrackScreenState extends State<PassengerTrackScreen> {
  final MapController _mapController = MapController();
  final SupabaseClient _client = Supabase.instance.client;
  Timer? _gpsTimer;

  LatLng? myPosition;
  bool _mapReady = false;

  String get _status => (widget.request['status'] ?? '').toString();
  String get _driverId => widget.request['driver_id'].toString();

  @override
  void initState() {
    super.initState();
    _initGps();
    _gpsTimer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
  }

  Future<void> _initGps() async {
    final pos = await LocationService.getCurrentPosition();
    if (!mounted || pos == null) return;
    setState(() => myPosition = pos);
    if (_mapReady) {
      _mapController.move(pos, 12);
    }
  }

  Future<void> _tick() async {
    final status = _status;
    if (!TripService.isPaidStatus(status)) return;
    if (status == 'dropped_off') return;

    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (pos != null) {
      setState(() => myPosition = pos);
    }

    if (status == 'confirmed') {
      final post = await _client
          .from('posts')
          .select('departure_at, time')
          .eq('id', widget.request['ride_id'].toString())
          .maybeSingle();
      if (!mounted) return;
      final departure = TripService.resolveDeparture(post);
      if (post != null && TripService.trackingOpen(departure)) {
        await _shareLocation();
      }
    }
  }

  Future<void> _shareLocation() async {
    final uid = _client.auth.currentUser?.id ?? '';
    if (uid.isEmpty || myPosition == null) return;
    try {
      await _client.from('profiles').update({
        'lat': myPosition!.latitude,
        'lng': myPosition!.longitude,
      }).eq('id', uid);
    } catch (_) {}
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SheetPage(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MicroLabel('Live tracking', color: AppColors.accent),
                          const SizedBox(height: 5),
                          Text(
                            "${widget.request['from']} → ${widget.request['to']}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
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
              const SizedBox(height: 14),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: LiveQuery.watch(
                    table: 'posts',
                    eq1Column: 'id',
                    eq1Value: widget.request['ride_id'].toString(),
                  ),
                  builder: (context, postSnap) {
                    final post =
                        (postSnap.hasData && postSnap.data!.isNotEmpty)
                            ? postSnap.data!.first
                            : null;
                    final departure = TripService.resolveDeparture(post);
                    final tripStatus =
                        (post?['trip_status'] ?? 'scheduled').toString();
                    final showDriverMarker =
                        _status == 'confirmed' &&
                            TripService.trackingOpen(departure);

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: LiveQuery.watch(
                        table: 'profiles',
                        eq1Column: 'id',
                        eq1Value: _driverId,
                        interval: const Duration(seconds: 10),
                      ),
                      builder: (context, driverSnap) {
                        final driverData =
                            (driverSnap.hasData && driverSnap.data!.isNotEmpty)
                                ? driverSnap.data!.first
                                : null;

                        return _buildMapAndPanel(
                          departure,
                          tripStatus,
                          showDriverMarker,
                          driverData,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapAndPanel(
    DateTime? departure,
    String tripStatus,
    bool showDriverMarker,
    Map<String, dynamic>? driverData,
  ) {
    final routePoints =
        CityLocations.buildRoute(widget.request['from']?.toString(),
            widget.request['to']?.toString());

    final showRoute = _status == 'picked_up' ||
        _status == 'dropped_off' ||
        tripStatus == 'in_progress';

    final markers = <Marker>[];
    if (myPosition != null) {
      markers.add(
        Marker(
          point: myPosition!,
          width: 50,
          height: 50,
          child: const MapMarker(icon: Icons.person_pin_circle_rounded),
        ),
      );
    }
    if (showDriverMarker &&
        driverData != null &&
        driverData['lat'] is num &&
        driverData['lng'] is num) {
      markers.add(
        Marker(
          point: LatLng(
            (driverData['lat'] as num).toDouble(),
            (driverData['lng'] as num).toDouble(),
          ),
          width: 50,
          height: 50,
          child: const MapMarker(icon: Icons.directions_car),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  myPosition ?? const LatLng(9.0054, 38.7636),
              initialZoom: 11,
              backgroundColor: AppColors.background,
              onMapReady: () {
                _mapReady = true;
                if (myPosition != null) {
                  _mapController.move(myPosition!, 11);
                }
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
              if (showRoute && routePoints != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.5,
                      color: AppColors.primaryVivid.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                showFlutterMapAttribution: false,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _buildStatusPanel(departure, tripStatus, showDriverMarker),
        ),
      ],
    );
  }

  Widget _buildStatusPanel(
    DateTime? departure,
    String tripStatus,
    bool showDriverMarker,
  ) {
    IconData icon;
    Color color;
    String title;
    String message;

    switch (_status) {
      case 'confirmed':
        color = AppColors.success;
        icon = Icons.payments_rounded;
        title = "Payment verified — seat reserved";
        message = TripService.trackingOpen(departure)
            ? "You can see your driver's live location on the map."
            : "Live tracking opens automatically 1 day before departure.\n${TripService.countdownText(departure)}";
        break;
      case 'picked_up':
        icon = Icons.route_rounded;
        color = AppColors.primaryVivid;
        title = "On board";
        message =
            "Driver-to-you tracking has stopped. Your route to ${widget.request['to']} is shown on the map.";
        break;
      case 'dropped_off':
        icon = Icons.celebration_rounded;
        color = AppColors.gold;
        title = "Trip completed successfully";
        message =
            "You arrived at ${widget.request['to']}. Your ticket remains valid as evidence.";
        break;
      default:
        icon = Icons.hourglass_top_rounded;
        color = AppColors.warning;
        title = "Waiting for payment verification";
        message = "The driver will verify your receipt shortly.";
    }

    if (_status == 'confirmed' && tripStatus == 'in_progress') {
      title = "Trip in progress";
      message =
          "The driver has started the trip. Route to ${widget.request['to']} is on your map.";
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  label: "View Ticket",
                  icon: Icons.confirmation_number_rounded,
                  onTap: () => Navigator.push(
                    context,
                    SlideUpRoute(page: TicketScreen(request: widget.request)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
