import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PassengerHomeScreen extends StatefulWidget {
  @override
  _PassengerHomeScreenState createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int selectedIndex = 0;

  final MapController mapController = MapController();

  LatLng currentLocation = LatLng(9.5931, 41.8661); // Dire Dawa

  String pickup = "";
  String destination = "";

  void openSearch() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _searchSheet(),
    );

    if (result != null) {
      setState(() {
        pickup = result["pickup"]!;
        destination = result["destination"]!;
      });
    }
  }

  Widget _searchSheet() {
    TextEditingController pickupController = TextEditingController();
    TextEditingController destinationController = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pickupController,
              decoration: InputDecoration(
                labelText: "Pickup location",
                prefixIcon: Icon(Icons.my_location),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: destinationController,
              decoration: InputDecoration(
                labelText: "Destination",
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "pickup": pickupController.text,
                  "destination": destinationController.text,
                });
              },
              child: Text("Confirm"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺️ MAP BACKGROUND
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
            ],
          ),

          // UI OVERLAY
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: 10),

                  // TOP BAR
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage:
                              NetworkImage("https://i.pravatar.cc/150?img=3"),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            destination.isEmpty ? "Where to?" : destination,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        Icon(Icons.notifications, color: Colors.purple),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),

                  // SEARCH BAR (CLICKABLE)
                  GestureDetector(
                    onTap: openSearch,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.purple),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              destination.isEmpty ? "Where to?" : destination,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          Icon(Icons.access_time, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "RECENT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  SizedBox(height: 15),

                  // HOME CARD CLICKABLE
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        destination = "Home";
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.home, color: Colors.purple),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Home",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text("Saved location",
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),

                  Spacer(),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car,
                            size: 16, color: Colors.purple),
                        SizedBox(width: 5),
                        Text("3 min"),
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
              backgroundColor: Colors.white,
              onPressed: () {
                mapController.move(currentLocation, 15);
              },
              child: Icon(Icons.my_location, color: Colors.purple),
            ),
          ),

          // BOTTOM NAV
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(Icons.home, "HOME", 0),
                  _navItem(Icons.receipt_long, "ACTIVITY", 1),
                  _navItem(Icons.person, "PROFILE", 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.purple : Colors.grey),
          SizedBox(height: 5),
          Text(label,
              style:
                  TextStyle(color: isSelected ? Colors.purple : Colors.grey)),
        ],
      ),
    );
  }
}
