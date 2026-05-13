import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'passenger_activity_screen.dart';

import 'passenger_home_screen.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    int currentIndex = 2;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Profile", style: TextStyle(color: Colors.black)),
        actions: [
          Icon(Icons.edit, color: Colors.purple),
          SizedBox(width: 15),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // PROFILE IMAGE
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
            ),

            SizedBox(height: 15),

            // NAME
            Text(
              user?.name ?? "Guest",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "PASSENGER",
                style: TextStyle(color: Colors.purple),
              ),
            ),

            SizedBox(height: 25),

            // 📊 STATS
            Row(
              children: [
                _statCard("Total Trips", "12"),
                SizedBox(width: 15),
                _statCard("Rewards", "1.2k"),
              ],
            ),

            SizedBox(height: 25),

            // MENU LIST
            _menuItem(Icons.history, "Trip History"),
            _menuItem(Icons.local_offer, "Promotions"),
            _menuItem(Icons.settings, "Settings"),

            SizedBox(height: 30),

            // 🚪 LOGOUT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                ),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text(
                  "Log Out",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
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

    // RIDE POST
    else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerActivityScreen(),
        ),
      );
    }

    // PROFILE
    else if (index == 3) {
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

  Widget _statCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
