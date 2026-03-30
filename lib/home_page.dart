import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Icon(Icons.menu, color: Colors.black),
        title: Text(
          "Safe and Reliable Rides",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Icon(Icons.person, color: Colors.white),
            ),
          )
        ],
      ),

      /// BODY
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LOCATION TEXT
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Your current locations",
                    style: TextStyle(color: Colors.grey)),

                SizedBox(height: 5),

                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.purple),
                    SizedBox(width: 5),
                    Text(
                      "Dire Dawa ,Ethiopia",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.keyboard_arrow_down)
                  ],
                ),
              ],
            ),
          ),

          /// MAP AREA (temporary)
          Container(
            height: 150,
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[300],
            ),
            child: Center(child: Text("Map Area")),
          ),

          SizedBox(height: 15),

          /// SEARCH BAR
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Where do you wanna go?",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

          SizedBox(height: 15),

          /// OPTION 1
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.star, color: Colors.black),
            ),
            title: Text("Choose a saved place"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),

          Divider(),

          /// OPTION 2
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.location_on, color: Colors.black),
            ),
            title: Text("Set distination on map"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),

          Spacer(),

          /// BOTTOM NAV
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home, color: Colors.black),
                    Text("Home"),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history, color: Colors.grey),
                    Text("History"),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, color: Colors.grey),
                    Text("Account"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}