import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Color(0xFF050816),

      appBar: AppBar(
        title: Text(
          "Trip History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF11151F),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("ride_history")
            .where(
              "driverId",
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return Center(
              child: Text(
                "No completed trips",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: rides.length,

            itemBuilder: (context, index) {

              final ride = rides[index];

              return Container(
                margin: EdgeInsets.only(bottom: 15),
                padding: EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Color(0xFF11151F),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(
                      "${ride['from']} → ${ride['to']}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      "Passenger: ${ride['passengerName']}",
                      style: TextStyle(color: Colors.white70),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Earned: ${ride['price']} ETB",
                      style: TextStyle(color: Colors.white70),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "COMPLETED",
                      style: TextStyle(
                        color: Colors.greenAccent,
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
    );
  }
}