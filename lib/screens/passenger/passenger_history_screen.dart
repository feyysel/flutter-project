import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassengerHistoryScreen extends StatelessWidget {
  const PassengerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050816),

      appBar: AppBar(
        title: Text(
          "Ride History",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF11151F),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("ride_history")
            .where(
              "passengerId",
              isEqualTo: FirebaseAuth.instance.currentUser!.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final rides = snapshot.data!.docs;

          if (rides.isEmpty) {
            return Center(
              child: Text(
                "No completed rides",
                style: TextStyle(color: Colors.white),
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
                      "Price: ${ride['price']} ETB",
                      style: TextStyle(color: Colors.grey),
                    ),

                    SizedBox(height: 6),

                    Text(
                      "Status: COMPLETED",
                      style: TextStyle(
                        color: Colors.green,
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