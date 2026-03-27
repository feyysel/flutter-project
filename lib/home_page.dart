import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fake Map Background
          Container(
            height: double.infinity,
            width: double.infinity,
            color: const Color.fromARGB(255, 196, 140, 140),
            child: Center(child: Text("Map Coming Soon")),
          ),

          // Top Text
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Text(
              "Safe and Reliable Rides at Your Fingertips",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Bottom Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildRow("From", "Addis Ababa"),
                  SizedBox(height: 10),
                  buildRow("To", "Dire Dawa"),
                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {},
                    child: Text("Search Ride"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRow(String title, String location) {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.blue),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey)),
            Text(location, style: TextStyle(fontSize: 16)),
          ],
        )
      ],
    );
  }
}