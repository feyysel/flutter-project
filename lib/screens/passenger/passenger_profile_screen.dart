import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'passenger_activity_screen.dart';
import 'passenger_history_screen.dart';
import 'passenger_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() =>
      _PassengerProfileScreenState();
}

class _PassengerProfileScreenState
    extends State<PassengerProfileScreen> {

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final imageController = TextEditingController();

  void showEditProfileDialog(dynamic userData) {

    nameController.text = userData?["name"] ?? "";
    phoneController.text = userData?["phone"] ?? "";
    imageController.text = userData?["profileImage"] ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF11151F), // DARK

          title: Text(
            "Edit Profile",
            style: TextStyle(color: Colors.white),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextField(
                  controller: nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Name",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),

                SizedBox(height: 15),

                TextField(
                  controller: phoneController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Phone",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),

                SizedBox(height: 15),

                TextField(
                  controller: imageController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Profile Image URL",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel",
                  style: TextStyle(color: Colors.grey)),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),

              onPressed: () async {

                final user = FirebaseAuth.instance.currentUser;

                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(user!.uid)
                    .update({
                  "name": nameController.text,
                  "phone": phoneController.text,
                  "profileImage": imageController.text,
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("Profile updated"),
                  ),
                );

                setState(() {});
              },

              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final firebaseUser = FirebaseAuth.instance.currentUser;
    int currentIndex = 2;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(firebaseUser?.uid)
          .get(),

      builder: (context, snapshot) {

        Map<String, dynamic>? user;

        if (snapshot.hasData &&
            snapshot.data!.data() != null) {
          user = snapshot.data!.data() as Map<String, dynamic>;
        }

        return Scaffold(
          backgroundColor: Color(0xFF050816), // DARK

          appBar: AppBar(
            backgroundColor: Color(0xFF11151F),
            elevation: 0,
            title: Text(
              "Profile",
              style: TextStyle(color: Colors.white),
            ),

            actions: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.deepPurple),
                onPressed: () {
                  showEditProfileDialog(user);
                },
              ),
            ],
          ),

          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),

            child: Column(
              children: [

                CircleAvatar(
                  radius: 40,
                  backgroundImage: user != null &&
                          user["profileImage"] != null &&
                          user["profileImage"] != ""
                      ? NetworkImage(user["profileImage"])
                      : null,
                  child: user == null ||
                          user["profileImage"] == null ||
                          user["profileImage"] == ""
                      ? Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                  backgroundColor: Color(0xFF11151F),
                ),

                SizedBox(height: 15),

                Text(
                  user?["name"] ?? "Guest",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 8),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "PASSENGER",
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                ),

                SizedBox(height: 25),

                Row(
                  children: [
                    _statCard("Total Trips", "12"),
                    SizedBox(width: 15),
                    _statCard("Rewards", "1.2k"),
                  ],
                ),

                SizedBox(height: 25),

                _menuItem(Icons.history, "Trip History",
                    onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PassengerHistoryScreen()),
                  );
                }),

                _menuItem(Icons.local_offer, "Promotions"),
                _menuItem(Icons.settings, "Settings"),

                SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF11151F),
                    ),

                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },

                    child: Text(
                      "Log Out",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Color(0xFF11151F),
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,

            onTap: (index) {
              setState(() {
                currentIndex = index;
              });

              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PassengerHomeScreen()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PassengerActivityScreen()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => PassengerProfileScreen()),
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
      },
    );
  }

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF11151F),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: Color(0xFF11151F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}