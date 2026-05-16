import 'package:flutter/material.dart';
import 'passenger_profile_screen.dart';
import 'passenger_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() => _PassengerActivityScreenState();
}

class _PassengerActivityScreenState extends State<PassengerActivityScreen> {
  @override
  Widget build(BuildContext context) {
    int currentIndex = 1; 

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: 
        Text("Activity"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 10,
      ),
      body: StreamBuilder<QuerySnapshot>(

  stream: FirebaseFirestore.instance
    .collection("ride_requests")
    .where(
      "passengerId",
      isEqualTo:
          FirebaseAuth.instance.currentUser!.uid,
    )
   // .orderBy("createdAt", descending: true)
    .snapshots(),

  builder: (context, snapshot) {

    if (snapshot.connectionState ==
        ConnectionState.waiting) {

      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!snapshot.hasData ||
        snapshot.data!.docs.isEmpty) {

      return Center(
        child: Text(
          "No ride activity yet",
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
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),

            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
              ),
            ],
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

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
                        fontWeight:
                            FontWeight.bold,
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
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: Text(
                      ride['status']
                          .toString()
                          .toUpperCase(),

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14),

              Text(
                "Price: ${ride['price']} ETB",
              ),

              SizedBox(height: 6),

              Text(
                "Passenger: ${ride['passengerName']}",
              ),

              SizedBox(height: 6),

              if (ride['status'] == "pending")
                Text(
                  "Waiting for driver acceptance",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

              if (ride['status'] == "accepted")
                Text(
                  "Driver accepted your ride",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

              if (ride['status'] == "completed")
                Text(
                  "Ride completed successfully",
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight:
                        FontWeight.bold,
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
          builder: (_) => PassengerHomeScreen(),
        ),
      );
    }

    // Activity
    else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerActivityScreen(),
        ),
      );
    }

    // PROFILE
    else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerProfileScreen(),
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
      icon: Icon(Icons.receipt_long),
      label: "Activity",
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