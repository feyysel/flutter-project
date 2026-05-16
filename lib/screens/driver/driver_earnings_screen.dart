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
        backgroundColor: Color(0xFF050816),
        elevation: 0,
        title: Text("Earnings"),
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
        child:
            CircularProgressIndicator(),
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
              color: Colors.deepPurple,

              borderRadius:
                  BorderRadius.circular(
                25,
              ),
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
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 25),

          Expanded(
            child: ListView.builder(

              itemCount: rides.length,

              itemBuilder:
                  (context, index) {

                final ride =
                    rides[index];

                return Container(
                  margin: EdgeInsets.only(
                    bottom: 15,
                  ),

                  padding: EdgeInsets.all(
                    18,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                        children: [

                          Text(
                            "${ride['from']} → ${ride['to']}",

                            style: TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 17,
                            ),
                          ),

                          SizedBox(height: 6),

                          Text(
                            ride['passengerName'],
                          ),
                        ],
                      ),

                      Text(
                        "+ ${ride['price']} ETB",

                        style: TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.bold,
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
  backgroundColor: Colors.white,
  selectedItemColor: Colors.deepPurple,
  unselectedItemColor: Colors.grey,
  type: BottomNavigationBarType.fixed,

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

  Widget earningsCard({
    required String title,
    required String amount,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF11151F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [

          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),

          Text(
            amount,
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}