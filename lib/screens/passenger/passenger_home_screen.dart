import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'ride_list_screen.dart';
import 'passenger_profile_screen.dart';
import 'passenger_activity_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/location_service.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  _PassengerHomeScreenState createState() =>
      _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int currentIndex = 0;

  final MapController mapController = MapController();

  LatLng currentLocation = LatLng(9.5931, 41.8661);

  bool _mapReady = false;

  String pickup = "";
  String destination = "";

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
      setState(() {
        currentLocation = position;
      });
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
    final user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection("notifications")
        .where("userId", isEqualTo: user!.uid)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.deepPurple,
            content: Text(data["title"]),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050816),

      body: Stack(
        children: [

         // ================= REAL MAP =================
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
        urlTemplate: 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
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
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .where("isOnline", isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          final markers = <Marker>[];
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            final lat = data?["lat"];
            final lng = data?["lng"];
            if (lat is num && lng is num) {
              markers.add(
                Marker(
                  point: LatLng(lat.toDouble(), lng.toDouble()),
                  width: 44,
                  height: 44,
                  child: const MapMarker(
                    icon: Icons.directions_car,
                  ),
                ),
              );
            }
          }
          if (markers.isEmpty) {
            return const SizedBox.shrink();
          }
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

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [

                  SizedBox(height: 10),

                  // TOP BAR
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        CircleAvatar(
  radius: 18,
  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
  child: Icon(
    Icons.person,
    color: AppColors.primary,
    size: 20,
  ),
),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            destination.isEmpty
                                ? "Where to?"
                                : destination,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.notifications,
                              color: AppColors.primary, size: 20),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),

                  // SEARCH BAR
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RideListScreen()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: AppGradients.surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.border),
                      ),

                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: AppColors.primary),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              destination.isEmpty
                                  ? "Where to?"
                                  : destination,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                          Icon(Icons.arrow_forward,
                              color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "RECENT",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  SizedBox(height: 15),

                  // HOME CARD
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        destination = "Home";
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),

                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.home,
                                color: Colors.white),
                          ),

                          SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Home",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Saved location",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),

                          Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  Spacer(),

                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 16, color: AppColors.gold),
                        SizedBox(width: 5),
                        Text("3 min",
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),

                  SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // LOCATION BUTTON
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.surfaceHigh,
              elevation: 6,
              onPressed: () {
                mapController.move(currentLocation, 15);
              },
              child: Icon(Icons.my_location,
                  color: AppColors.primary),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Color(0xFF11151F),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => PassengerHomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => PassengerActivityScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => PassengerProfileScreen()),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Activity"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}