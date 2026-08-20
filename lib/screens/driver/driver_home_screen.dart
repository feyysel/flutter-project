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

class DriverHomeScreen extends StatefulWidget {
  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isOnline = true;
  int currentIndex = 0;

  final MapController mapController = MapController();
  LatLng currentLocation = const LatLng(9.5931, 41.8661);
  bool _mapReady = false;

  Timer? _locationTimer;
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  Future<void> _persistLocation(LatLng position) async {
    if (_currentUserId.isEmpty) return;
    await _supabase.from('profiles').update({
      'lat': position.latitude,
      'lng': position.longitude,
    }).eq('id', _currentUserId);
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

    await for (final snapshot in _supabase
        .from('ride_history')
        .stream(primaryKey: ['id'])
        .eq('driver_id', _currentUserId)) {

      double totalEarnings = 0;
      int totalTrips = snapshot.length;

      for (var data in snapshot) {
        totalEarnings += double.tryParse(data["price"].toString()) ?? 0;
      }

      yield {
        "earnings": totalEarnings,
        "trips": totalTrips,
      };
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

  void listenNotifications() {
    if (_currentUserId.isEmpty) return;

    _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId)
        .listen((snapshot) {
      for (var data in snapshot) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.deepPurple,
            content: Text(data["title"] ?? ""),
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
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF11151F),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "DriveOn",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050816),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color.fromARGB(255, 200, 198, 198),
                                fontWeight: FontWeight.bold,
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

                          await _supabase.from('profiles').update({
                            'is_online': newStatus,
                            if (position != null)
                              'lat': position.latitude,
                            if (position != null)
                              'lng': position.longitude,
                          }).eq('id', _currentUserId);

                          final posts = await _supabase
                              .from('posts')
                              .select()
                              .eq('driver_id', _currentUserId);

                          for (var post in posts) {
                            await _supabase.from('posts').update({
                              'is_online': newStatus,
                              if (position != null)
                                'lat': position.latitude,
                              if (position != null)
                                'lng': position.longitude,
                            }).eq('id', post['id']);
                          }

                          if (newStatus) {
                            _startLocationUpdates();
                          } else {
                            _stopLocationUpdates();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOnline ? "Go Offline" : "Go Online",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                          color: const Color(0xFF050816),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("TOTAL EARNINGS",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text("$earnings ETB",
                                    style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple)),
                              ],
                            ),
                            Column(
                              children: [
                                const Text("TRIPS",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.directions_car,
                                        color: Colors.deepPurple),
                                    const SizedBox(width: 6),
                                    Text("$trips",
                                        style: const TextStyle(
                                            fontSize: 34,
                                            color: Colors.deepPurple,
                                            fontWeight: FontWeight.bold)),
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
                          color: const Color(0xFF050816),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 15),
                            const Text("No ride requests available",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text("Waiting for passenger requests...",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final requests = snapshot.data!;
                    final pendingAccepted = requests
                        .where((r) =>
                            r['status'] == 'pending' ||
                            r['status'] == 'accepted')
                        .toList();

                    if (pendingAccepted.isEmpty) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: const Color(0xFF050816),
                          borderRadius: BorderRadius.circular(35),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none,
                                size: 60, color: Colors.grey),
                            const SizedBox(height: 15),
                            const Text("No ride requests available",
                                style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text("Waiting for passenger requests...",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    Map<String, List<Map<String, dynamic>>> groupedRequests = {};
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
                            color: const Color(0xFF050816),
                            margin: const EdgeInsets.only(bottom: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${firstRequest['from']} → ${firstRequest['to']}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Passengers (${rideRequests.length})",
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  const SizedBox(height: 15),
                                  ...rideRequests.map((request) {
                                    return Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 15),
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF11151F),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            request["passenger_name"] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            request["passenger_phone"] ?? '',
                                            style: const TextStyle(
                                                color: Colors.white70),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "${request["price"]} ETB",
                                            style: const TextStyle(
                                                color: Colors.deepPurple,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 15),
                                          Column(
                                            children: [
                                              if (request["status"] ==
                                                  "pending")
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.grey,
                                                    ),
                                                    onPressed: () async {
                                                      await RideService
                                                          .updateRideRequest(
                                                              request['id'],
                                                              {
                                                            'status':
                                                                'declined',
                                                          });
                                                    },
                                                    child: const Text(
                                                        "Decline"),
                                                  ),
                                                ),
                                              const SizedBox(height: 10),
                                              SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        Colors.deepPurple,
                                                  ),
                                                  onPressed: () async {
                                                    await RideService
                                                        .updateRideRequest(
                                                            request['id'], {
                                                      'status': 'accepted',
                                                    });

                                                    await _supabase
                                                        .from('posts')
                                                        .update({
                                                      'available_seats':
                                                          request['available_seats'] -
                                                              1,
                                                    }).eq('id',
                                                            request['ride_id']);

                                                    final ride =
                                                        await _supabase
                                                            .from('posts')
                                                            .select()
                                                            .eq('id',
                                                                request['ride_id'])
                                                            .maybeSingle();

                                                    if (ride != null &&
                                                        (ride['available_seats'] ??
                                                                0) <=
                                                            0) {
                                                      await _supabase
                                                          .from('posts')
                                                          .update({
                                                        'is_full': true,
                                                      }).eq('id',
                                                              request['ride_id']);
                                                    }

                                                    await RideService
                                                        .addNotification(
                                                      userId: request[
                                                          'passenger_id'],
                                                      title:
                                                          "Ride Accepted",
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
                                              padding:
                                                  const EdgeInsets.only(
                                                      top: 12),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton(
                                                  style: ElevatedButton
                                                      .styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                  onPressed: () async {
                                                    await RideService
                                                        .updateRideRequest(
                                                            request['id'], {
                                                      'status': 'completed',
                                                    });

                                                    await RideService
                                                        .addRideHistory({
                                                      ...request,
                                                      'status': 'completed',
                                                    });

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            "Ride Completed"),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                      "Complete Ride"),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: const Color(0xFF050816),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => DriverHomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => DriverRidePostScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => DriverEarningsScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => DriverProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle), label: "Ride Post"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: "Earnings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget navItem({
    required IconData icon,
    required String label,
    bool selected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: selected ? Colors.deepPurple : Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: selected ? Colors.deepPurple : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
