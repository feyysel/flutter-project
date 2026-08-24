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
import '../../widgets/slide_action_button.dart';

class DriverTripScreen extends StatefulWidget {
  const DriverTripScreen({super.key, required this.rideId});

  final String rideId;

  @override
  State<DriverTripScreen> createState() => _DriverTripScreenState();
}

class _DriverTripScreenState extends State<DriverTripScreen> {
  final MapController _mapController = MapController();
  final SupabaseClient _client = Supabase.instance.client;
  Timer? _locationTimer;

  LatLng currentLocation = const LatLng(9.0054, 38.7636);
  bool _mapReady = false;

  String get _currentUserId => _client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _initLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final position = await LocationService.getCurrentPosition();
      if (!mounted || position == null) return;
      setState(() => currentLocation = position);
      if (_mapReady) {
        _mapController.move(position, _mapController.camera.zoom);
      }
      await _persistLocation(position);
    });
  }

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (position != null) {
      setState(() => currentLocation = position);
      await _persistLocation(position);
    }
  }

  Future<void> _persistLocation(LatLng position) async {
    if (_currentUserId.isEmpty) return;
    try {
      await _client.from('profiles').update({
        'lat': position.latitude,
        'lng': position.longitude,
      }).eq('id', _currentUserId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'picked_up':
        return AppColors.primaryVivid;
      case 'dropped_off':
        return AppColors.gold;
      case 'payment_submitted':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'payment_submitted':
        return "Receipt sent";
      case 'confirmed':
        return "Paid";
      case 'picked_up':
        return "On board";
      case 'dropped_off':
        return "Arrived";
      default:
        return status.toUpperCase();
    }
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
                          const MicroLabel('Trip console', color: AppColors.accent),
                          const SizedBox(height: 5),
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _postStream(),
                            builder: (context, snap) {
                              final post = _firstOf(snap);
                              return Text(
                                "${post?['from'] ?? ''} → ${post?['to'] ?? ''}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: AppColors.textPrimary,
                                ),
                              );
                            },
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
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _postStream(),
                  builder: (context, postSnap) {
                    final post = _firstOf(postSnap);
                    final tripStatus =
                        (post?['trip_status'] ?? 'scheduled').toString();

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _requestsStream(),
                      builder: (context, reqSnap) {
                        final allRequests = reqSnap.data ?? [];
                        final passengers = allRequests
                            .where((r) =>
                                r['driver_id'].toString() == _currentUserId &&
                                TripService.isPaidStatus(r['status']))
                            .toList()
                          ..sort((a, b) => (a['passenger_name'] ?? '')
                              .toString()
                              .compareTo((b['passenger_name'] ?? '').toString()));

                        final unpickedIds = passengers
                            .where((p) => p['status'] == 'confirmed')
                            .map((p) => p['passenger_id'].toString())
                            .toList();

                        final allPicked = passengers.isNotEmpty &&
                            passengers.every((p) => p['status'] != 'confirmed');
                        final allDropped = passengers.isNotEmpty &&
                            passengers.every((p) => p['status'] == 'dropped_off');

                        return StreamBuilder<List<Map<String, dynamic>>>(
                          stream: unpickedIds.isEmpty
                              ? const Stream.empty()
                              : LiveQuery.watch(
                                  table: 'profiles',
                                  inColumn: 'id',
                                  inValues: unpickedIds,
                                  interval: const Duration(seconds: 10),
                                ),
                          builder: (context, profilesSnap) {
                            final profiles = profilesSnap.data ?? [];
                            return _buildBody(
                              post: post,
                              tripStatus: tripStatus,
                              passengers: passengers,
                              profiles: profiles,
                              allPicked: allPicked,
                              allDropped: allDropped,
                            );
                          },
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

  Stream<List<Map<String, dynamic>>> _postStream() {
    return LiveQuery.watch(
      table: 'posts',
      eq1Column: 'id',
      eq1Value: widget.rideId,
    );
  }

  Stream<List<Map<String, dynamic>>> _requestsStream() {
    return LiveQuery.watch(
      table: 'ride_requests',
      eq1Column: 'ride_id',
      eq1Value: widget.rideId,
    );
  }

  Map<String, dynamic>? _firstOf(
      AsyncSnapshot<List<Map<String, dynamic>>> snap) {
    if (!snap.hasData || snap.data!.isEmpty) return null;
    return snap.data!.first;
  }

  Widget _buildBody({
    required Map<String, dynamic>? post,
    required String tripStatus,
    required List<Map<String, dynamic>> passengers,
    required List<Map<String, dynamic>> profiles,
    required bool allPicked,
    required bool allDropped,
  }) {
    final departure = TripService.resolveDeparture(post);
    final showRoute = allPicked || tripStatus == 'in_progress';
    final routePoints =
        CityLocations.buildRoute(post?['from']?.toString(), post?['to']?.toString());
    final tripDone = tripStatus == 'completed';

    final markers = <Marker>[
      Marker(
        point: currentLocation,
        width: 50,
        height: 50,
        child: const MapMarker(icon: Icons.directions_car),
      ),
    ];

    for (final profile in profiles) {
      if (profile['lat'] is num && profile['lng'] is num) {
        markers.add(
          Marker(
            point: LatLng(
              (profile['lat'] as num).toDouble(),
              (profile['lng'] as num).toDouble(),
            ),
            width: 46,
            height: 46,
            child: const MapMarker(icon: Icons.person_pin_circle_rounded),
          ),
        );
      }
    }

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 10,
                    backgroundColor: AppColors.background,
                    onMapReady: () {
                      _mapReady = true;
                      _mapController.move(currentLocation, 10);
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
                            color:
                                AppColors.primaryVivid.withValues(alpha: 0.9),
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
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tripDone
                            ? Icons.verified_rounded
                            : Icons.schedule_rounded,
                        size: 15,
                        color: tripDone
                            ? AppColors.success
                            : AppColors.accent,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        tripDone
                            ? "TRIP COMPLETED"
                            : TripService.countdownText(departure),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showRoute && routePoints == null)
                Positioned(
                  top: 52,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      "Route line unavailable for these city names.",
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: const BoxDecoration(
              color: AppColors.background,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const MicroLabel('Passengers'),
                    const Spacer(),
                    Text(
                      "${passengers.length} verified",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: passengers.isEmpty
                      ? Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            "No verified passengers yet.\nThey appear here once payments are accepted.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: passengers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (context, index) =>
                              _passengerRow(passengers[index], tripDone),
                        ),
                ),

                if (!tripDone &&
                    post != null &&
                    allPicked &&
                    tripStatus != 'in_progress' &&
                    !allDropped) ...[
                  const SizedBox(height: 12),
                  SlideActionButton(
                    label: "SLIDE TO START TRIP",
                    successLabel: "TRIP STARTED",
                    onError: (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.danger,
                          content: Text("Could not start trip: $e"),
                        ),
                      );
                    },
                    onCompleted: () async {
                      await TripService.startTrip(
                        post: post,
                        passengers: passengers,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text("Trip started"),
                          ),
                        );
                      }
                    },
                  ),
                ],

                if (!tripDone && post != null && allDropped && passengers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SlideActionButton(
                    label: "SLIDE TO FINISH TRIP",
                    successLabel: "TRIP COMPLETED",
                    icon: Icons.flag_rounded,
                    onError: (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.danger,
                          content: Text("Could not finish trip: $e"),
                        ),
                      );
                    },
                    onCompleted: () async {
                      await TripService.finishTrip(
                        post: post,
                        passengers: passengers,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text("Trip completed successfully"),
                          ),
                        );
                      }
                    },
                  ),
                ],

                if (tripDone) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(27),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.45)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 19, color: AppColors.success),
                        SizedBox(width: 8),
                        Text(
                          "Trip completed successfully",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _passengerRow(Map<String, dynamic> passenger, bool tripDone) {
    final status = (passenger['status'] ?? '').toString();
    final canPick = status == 'confirmed' && !tripDone;
    final canDrop = status == 'picked_up' && !tripDone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "${passenger['passenger_name'] ?? 'Passenger'}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      _statusLabel(status),
                      color: _statusColor(status),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "${passenger['passenger_phone'] ?? ''}  •  ${passenger['price'] ?? '0'} ETB",
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: canPick ? () => _pick(passenger) : null,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: status == 'picked_up' ||
                        status == 'dropped_off'
                    ? AppColors.success
                    : canPick
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : AppColors.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: status == 'picked_up' || status == 'dropped_off'
                      ? AppColors.success
                      : canPick
                          ? AppColors.primary
                          : AppColors.border,
                ),
              ),
              child: Icon(
                status == 'picked_up' || status == 'dropped_off'
                    ? Icons.check_rounded
                    : Icons.event_available_rounded,
                size: 19,
                color: status == 'picked_up' || status == 'dropped_off'
                    ? Colors.white
                    : canPick
                        ? AppColors.accent
                        : AppColors.textMuted,
              ),
            ),
          ),
          GestureDetector(
            onTap: canDrop ? () => _drop(passenger) : null,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: status == 'dropped_off'
                    ? AppColors.gold
                    : canDrop
                        ? AppColors.gold.withValues(alpha: 0.14)
                        : AppColors.surfaceHigh,
                shape: BoxShape.circle,
                border: Border.all(
                  color: status == 'dropped_off'
                      ? AppColors.gold
                      : canDrop
                          ? AppColors.gold
                          : AppColors.border,
                ),
              ),
              child: Icon(
                status == 'dropped_off'
                    ? Icons.check_rounded
                    : Icons.location_on_outlined,
                size: 19,
                color: status == 'dropped_off'
                    ? Colors.white
                    : canDrop
                        ? AppColors.gold
                        : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(Map<String, dynamic> passenger) async {
    try {
      await TripService.markPicked(passenger);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(
                "${passenger['passenger_name']} marked as picked up"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text("Failed to update pickup: $e"),
          ),
        );
      }
    }
  }

  Future<void> _drop(Map<String, dynamic> passenger) async {
    try {
      await TripService.markDropped(passenger);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.gold,
            content: Text(
                "${passenger['passenger_name']} dropped at destination"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text("Failed to update drop-off: $e"),
          ),
        );
      }
    }
  }
}
