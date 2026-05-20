import 'package:flutter/material.dart';
import 'passenger_profile_screen.dart';
import 'passenger_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() =>
      _PassengerActivityScreenState();
}

class _PassengerActivityScreenState
    extends State<PassengerActivityScreen> {
  @override
  Widget build(BuildContext context) {
    int currentIndex = 1;

    return Scaffold(
      backgroundColor: Color(0xFF050816),

      appBar: AppBar(
        title: Text("Activity",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF11151F),
        elevation: 10,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("ride_requests")
            .where(
              "passengerId",
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No ride activity yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final rides = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: rides.length,

            itemBuilder: (context, index) {
              final ride = rides[index];

              Color statusColor = Colors.orange;

              if (ride['status'] == "accepted") {
                statusColor = Colors.green;
              }

              if (ride['status'] == "completed") {
                statusColor = Colors.deepPurple;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Color(0xFF11151F),
                  borderRadius: BorderRadius.circular(22),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,

                      children: [

                        Expanded(
                          child: Text(
                            "${ride['from']} → ${ride['to']}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(14),
                          ),

                          child: Text(
                            ride['status']
                                .toString()
                                .toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 14),

                    Text(
                      "Price: ${ride['price']} ETB",
                      style: TextStyle(color: Colors.grey),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Passenger: ${ride['passengerName']}",
                      style: TextStyle(color: Colors.grey),
                    ),

                    SizedBox(height: 10),

                    if (ride['status'] == "pending")
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Waiting for driver acceptance",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,

                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),

                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("ride_requests")
                                    .doc(ride.id)
                                    .delete();

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content:
                                        Text("Ride request cancelled"),
                                  ),
                                );
                              },

                              child: Text("Cancel Request"),
                            ),
                          ),
                        ],
                      ),

                    if (ride['status'] == "accepted")
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Driver accepted your ride",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 14),

                          Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(18),
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(
                                  "Driver Details",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                SizedBox(height: 10),

                                Text(
                                  "Name: ${ride['driverName'] ?? ''}",
                                  style: TextStyle(color: Colors.grey),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  "Phone: ${ride['driverPhone'] ?? ''}",
                                  style: TextStyle(color: Colors.grey),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  "Plate Number: ${ride['driverPlate'] ?? ''}",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    if (ride['status'] == "completed")
                      Text(
                        "Ride completed successfully",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
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