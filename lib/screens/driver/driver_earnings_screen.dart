import 'package:flutter/material.dart';
import 'driver_profile_screen.dart';
import 'driver_ride_post_screen.dart';
import 'driver_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverEarningsScreen extends StatefulWidget {
  @override
  State<DriverEarningsScreen> createState() =>
      _DriverEarningsScreenState();
}

class _DriverEarningsScreenState
    extends State<DriverEarningsScreen> {

  int currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050816),

      appBar: AppBar(
         automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF11151F),
        elevation: 0,
        title: Text(
          "Earnings",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("ride_history")
            .where(
              "driverId",
              isEqualTo:
                  FirebaseAuth.instance.currentUser!.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final rides = snapshot.data!.docs;

          double total = 0;

          for (var ride in rides) {
            total += double.tryParse(
                  ride['price'].toString(),
                ) ??
                0;
          }

          return Padding(
            padding: EdgeInsets.all(16),

            child: Column(
              children: [

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(25),

                  decoration: BoxDecoration(
                    color: Color(0xFF11151F),
                    borderRadius: BorderRadius.circular(25),
                  ),

                  child: Column(
                    children: [

                      Text(
                        "TOTAL EARNINGS",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        "$total ETB",
                        style: TextStyle(
                          color: Colors.deepPurpleAccent,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),

                Expanded(
                  child: ListView.builder(
                    itemCount: rides.length,

                    itemBuilder: (context, index) {

                      final ride = rides[index];

                      return Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.all(18),

                        decoration: BoxDecoration(
                          color: Color(0xFF11151F),
                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,

                          children: [

                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [

                                Text(
                                  "${ride['from']} → ${ride['to']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.white,
                                  ),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  ride['passengerName'],
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),

                            Text(
                              "+ ${ride['price']} ETB",
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Color(0xFF11151F),
        selectedItemColor: Colors.deepPurpleAccent,
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
                builder: (_) => DriverHomeScreen(),
              ),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DriverRidePostScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DriverEarningsScreen(),
              ),
            );
          } else if (index == 3) {
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
            icon: Icon(Icons.map),
            label: "Map",
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
}