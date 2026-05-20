import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'ride_list_screen.dart';
import 'passenger_profile_screen.dart';
import 'passenger_activity_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  String pickup = "";
  String destination = "";

  @override
  void initState() {
    super.initState();
    listenNotifications();
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

         // ================= FAKE MAP (NETWORK IMAGE) =================
Container(
  width: double.infinity,
  height: double.infinity,
  decoration: BoxDecoration(
    image: DecorationImage(
      image: NetworkImage(
        "https://i1-e.pinimg.com/1200x/9e/1e/7c/9e1e7c7983352dc78b81a3dd53fc4013.jpg",
      ),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.blue.shade900.withOpacity(0.65),
        BlendMode.darken,
      ),
    ),
  ),
  child: Center(
    child: Icon(
      Icons.location_pin,
      color: Colors.deepPurple,
      size: 45,
    ),
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
                      color: Color(0xFF11151F),
                      borderRadius: BorderRadius.circular(30),
                    ),

                    child: Row(
                      children: [
                        CircleAvatar(
  radius: 18,
  backgroundColor: Color(0xFF11151F),
  child: Icon(
    Icons.person,
    color: Colors.white,
    size: 20,
  ),
),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            destination.isEmpty
                                ? "Where to?"
                                : destination,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),

                        Icon(Icons.notifications,
                            color: Colors.deepPurple),
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
                        color: Color(0xFF11151F),
                        borderRadius: BorderRadius.circular(30),
                      ),

                      child: Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.deepPurple),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              destination.isEmpty
                                  ? "Where to?"
                                  : destination,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),

                          Icon(Icons.access_time,
                              color: Colors.grey),
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
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        color: Color(0xFF11151F),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  Colors.deepPurple.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.home,
                                color: Colors.deepPurple),
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
                      color: Color(0xFF11151F),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car,
                            size: 16, color: Colors.deepPurple),
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
              backgroundColor: Color(0xFF11151F),
              onPressed: () {
                mapController.move(currentLocation, 15);
              },
              child: Icon(Icons.my_location,
                  color: Colors.deepPurple),
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