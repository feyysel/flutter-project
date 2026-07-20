import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'driver_profile_screen.dart';
import 'driver_ride_post_screen.dart';
import 'driver_earnings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverHomeScreen extends StatefulWidget {
  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool isOnline = true;
  int currentIndex=0;

  Stream<Map<String, dynamic>> getDriverStats() async* {

  final user =
      FirebaseAuth.instance.currentUser;

  if (user == null) return;

  await for (final snapshot
      in FirebaseFirestore.instance
          .collection("ride_history")
          .where(
            "driverId",
            isEqualTo: user.uid,
          )
          .snapshots()) {

    double totalEarnings = 0;
    int totalTrips = snapshot.docs.length;

    for (var doc in snapshot.docs) {

      final data = doc.data();

      totalEarnings += double.tryParse(
            data["price"].toString(),
          ) ??
          0;
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
}

void listenNotifications() {

  final user =
      FirebaseAuth.instance.currentUser;

  FirebaseFirestore.instance
      .collection("notifications")
      .where(
        "userId",
        isEqualTo: user!.uid,
      )
      .snapshots()
      .listen((snapshot) {

    for (var doc in snapshot.docs) {

      final data = doc.data();

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          backgroundColor: Colors.deepPurple,

          content: Text(
            data["title"],
          ),
        ),
      );
    }
  });
}
/*
Future<void> resetDriverEarnings() async {

  final user =
      FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final history = await FirebaseFirestore
      .instance
      .collection("ride_history")
      .where(
        "driverId",
        isEqualTo: user.uid,
      )
      .get();

  for (var doc in history.docs) {

    await doc.reference.update({
      "price": "0",
    });
  }

  ScaffoldMessenger.of(context).showSnackBar(

    SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        "Earnings reset successfully",
      ),
    ),
  );
}*/

  @override
  Widget build(BuildContext context) {
    final currentDriver=FirebaseAuth.instance.currentUser;
    return Scaffold(
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

          // ================= CONTENT =================
          SafeArea(
            child: Column(
              children: [

                // ================= TOP BAR =================
                Padding(
                  padding: const EdgeInsets.all(16),
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

                      Text(
                        "DriveOn",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),

                      Spacer(),

                      // Status
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF050816),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [

                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? Colors.green
                                    : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),

                            SizedBox(width: 6),

                            Text(
                              isOnline
                                  ? "YOU ARE ONLINE"
                                  : "YOU ARE OFFLINE",
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color.fromARGB(255, 200, 198, 198),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 10),

                      // Toggle
                      GestureDetector(
                        onTap: () async {

  final newStatus = !isOnline;

  setState(() {
    isOnline = newStatus;
  });

  final user =
      FirebaseAuth.instance.currentUser;

  // UPDATE USER STATUS
  await FirebaseFirestore.instance
      .collection("users")
      .doc(user!.uid)
      .update({
    "isOnline": newStatus,
  });

  // UPDATE ALL DRIVER POSTS
  final posts = await FirebaseFirestore
      .instance
      .collection("posts")
      .where("driverId",
          isEqualTo: user.uid)
      .get();

  for (var doc in posts.docs) {

    await FirebaseFirestore.instance
        .collection("posts")
        .doc(doc.id)
        .update({
      "isOnline": newStatus,
    });
  }
},
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOnline
                                ? "Go Offline"
                                : "Go Online",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= EARNING CARD =================
                Padding(
  padding:
      const EdgeInsets.symmetric(
    horizontal: 16,
  ),

  child: StreamBuilder<Map<String, dynamic>>(

    stream: getDriverStats(),

    builder: (context, snapshot) {

      double earnings = 0;
      int trips = 0;

      if (snapshot.hasData) {

        earnings =
            snapshot.data!["earnings"];

        trips =
            snapshot.data!["trips"];
      }

      return Container(
        padding: EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Color(0xFF050816),

          borderRadius:
              BorderRadius.circular(28),
        ),

        child: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,

          children: [

            // EARNINGS
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  "TOTAL EARNINGS",

                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "$earnings ETB",
                  

                  style: TextStyle(
                    fontSize: 34,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.deepPurple,
                  ),
                ),
              ],
            ),

            // TRIPS
            Column(
              children: [

                Text(
                  "TRIPS",

                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Row(
                  children: [

                    Icon(
                      Icons.directions_car,
                      color:
                          Colors.deepPurple,
                    ),

                    SizedBox(width: 6),

                    Text(
                      "$trips",

                      style: TextStyle(
                        fontSize: 34,
                        color:
                            Colors.deepPurple,
                        fontWeight:
                            FontWeight.bold,
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

                Spacer(),

                // ================= RIDE REQUEST CARD =================
StreamBuilder<QuerySnapshot>(

  stream: FirebaseFirestore.instance
    .collection("ride_requests")
    .where("driverId",
        isEqualTo: currentDriver?.uid)
    .where(
  "status",
  whereIn: ["pending", "accepted"],
)
    .snapshots(),

  builder: (context, snapshot) {

    if (!snapshot.hasData ||
        snapshot.data!.docs.isEmpty) {

      return Container(
        width: double.infinity,
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(25),

        decoration: BoxDecoration(
          color: Color(0xFF050816),
          borderRadius: BorderRadius.circular(35),
        ),

        child: Column(
          children: [

            Icon(
              Icons.notifications_none,
              size: 60,
              color: Colors.grey,
            ),

            SizedBox(height: 15),

            Text(
              "No ride requests available",

              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              "Waiting for passenger requests...",

              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final requests = snapshot.data!.docs;

Map<String, List<QueryDocumentSnapshot>> groupedRequests = {};

for (var request in requests) {
  final rideId = request["rideId"];

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
                  color: Colors.grey,
                  fontSize: 16,
                ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        request["passengerName"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        request["passengerPhone"],
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "${request["price"]} ETB",
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),


  Column(
    children: [
if (request["status"] == "pending")
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
          ),
          onPressed: () async {
            await FirebaseFirestore.instance
                .collection("ride_requests")
                .doc(request.id)
                .update({
              "status": "declined",
            });
          },
          child: const Text("Decline"),
        ),
      ),

      const SizedBox(height: 10),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
          ),
          onPressed: () async {

            await FirebaseFirestore.instance
                .collection("ride_requests")
                .doc(request.id)
                .update({
              "status": "accepted",
            });

            await FirebaseFirestore.instance
                .collection("notifications")
                .add({
              "userId": request["passengerId"],
              "title": "Ride Accepted",
              "body": "Driver accepted your ride",
              "createdAt": FieldValue.serverTimestamp(),
            });

          },
          child: const Text("Accept"),
        ),
      ),

    ],
  ),

if (request["status"] == "accepted")
  Padding(
    padding: const EdgeInsets.only(top: 12),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
        onPressed: () async {

          final requestData =
              request.data() as Map<String, dynamic>;

          // Mark request completed
          await FirebaseFirestore.instance
              .collection("ride_requests")
              .doc(request.id)
              .update({
            "status": "completed",
          });

          // Save history
          await FirebaseFirestore.instance
              .collection("ride_history")
              .add({

            ...requestData,

            "status": "completed",

            "completedAt":
                FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ride Completed"),
            ),
          );
        },
        child: const Text("Complete Ride"),
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
                // ================= BOTTOM NAV =================
              ],
            ),
          ),
        ],
      ),
bottomNavigationBar: BottomNavigationBar(
  currentIndex: currentIndex,
  backgroundColor:Color(0xFF050816),
  selectedItemColor: Colors.deepPurple,
  unselectedItemColor: Colors.grey,
  type: BottomNavigationBarType.fixed,
  elevation: 10,

  onTap: (index) {
    setState(() {
      currentIndex = index;
    });

    // HOME
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverHomeScreen(),
        ),
      );
    }

    // RIDE POST
    else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverRidePostScreen(),
        ),
      );
    }

    // EARNINGS
    else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverEarningsScreen(),
        ),
      );
    }

    // PROFILE
    else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverProfileScreen(),
        ),
      );
    }
  },

  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: "Home",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle),
      label: "Ride Post",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.account_balance_wallet),
      label: "Earnings",
    ),

    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: "Profile",
    ),
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

        Icon(
          icon,
          color: selected
              ? Colors.deepPurple
              : Colors.grey,
        ),

        SizedBox(height: 4),

        Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.deepPurple
                : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}