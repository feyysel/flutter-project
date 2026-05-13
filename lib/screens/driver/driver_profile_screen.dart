import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_ride_post_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_home_screen.dart';
class DriverProfileScreen extends StatefulWidget {
  @override
  State<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState
    extends State<DriverProfileScreen> {
      int currentIndex = 3;

  Map<String, dynamic>? driverData;

  @override
  void initState() {
    super.initState();
    loadDriverData();
  }

  // ================= LOAD DRIVER DATA =================
  Future<void> loadDriverData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    setState(() {
      driverData = doc.data();
    });
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/role-selection",
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {

    if (driverData == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF050816),

      body: SafeArea(
        child: Column(
          children: [

            // ================= TOP BAR =================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [

                  

                  Text(
                    "Driver Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Spacer(),

                  Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    SizedBox(height: 15),

                    // ================= PROFILE IMAGE =================
                    Stack(
                      children: [

                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.deepPurple,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: NetworkImage(
                              driverData!["profileImage"] ??
                                  "https://i.pravatar.cc/150?img=12",
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

                    // ================= DRIVER NAME =================
                    Text(
                      driverData!["name"] ?? "",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    // ================= DRIVER STATUS =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Icon(
                          Icons.star,
                          color: Colors.deepPurple,
                          size: 18,
                        ),

                        SizedBox(width: 5),

                        Text(
                          "4.95",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(width: 8),

                        Text(
                          "• Professional Driver",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 18),

// ================= VERIFY BUTTON =================
Container(
  padding: EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 10,
  ),
  decoration: BoxDecoration(
    color: Colors.deepPurple.withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.deepPurple,
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [

      Icon(
        Icons.verified,
        color: Colors.deepPurple,
        size: 18,
      ),

      SizedBox(width: 8),

      Text(
        driverData!["isVerified"] == true
            ? "Verified Driver"
            : "Verify Account",
        style: TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),

SizedBox(height: 28),

                    // ================= STATS =================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [

                          Expanded(
                            child: statCard(
                              title: "TOTAL TRIPS",
                              value: "0",
                            ),
                          ),

                          SizedBox(width: 14),

                          Expanded(
                            child: statCard(
                              title: "YEARS DRIVING",
                              value: "1",
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: 25,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF11151F),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [

                            Text(
                              "ACCEPTANCE",
                              style: TextStyle(
                                color: Colors.grey,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),

                            SizedBox(height: 10),

                            Text(
                              "98%",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 28),

                    // ================= VEHICLE =================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Active Vehicle",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF11151F),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [

                            // Car Image
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(14),
                              child: Image.network(
                                "https://images.unsplash.com/photo-1503376780353-7e6692767b70",
                                width: 110,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),

                            SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    driverData!["vehicleModel"] ??
                                        "Vehicle",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(height: 6),

                                  Text(
                                    driverData!["vehicleColor"] ??
                                        "Unknown Color",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    driverData!["plateNumber"] ??
                                        "",
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple,
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: Text(
                                "ACTIVE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // ================= SETTINGS =================
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Account Settings",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 18),

                    settingsTile(
                      icon: Icons.person,
                      title: "Personal Information",
                    ),

                    settingsTile(
                      icon: Icons.description,
                      title: "Documents & Insurance",
                    ),

                    settingsTile(
                      icon: Icons.settings,
                      title: "App Settings",
                    ),

                    settingsTile(
                      icon: Icons.help,
                      title: "Help & Support",
                    ),

                    SizedBox(height: 35),

                    GestureDetector(
                      onTap: logout,
                      child: Text(
                        "Sign Out",
                        style: TextStyle(
                          color: Colors.pink,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    SizedBox(height: 35),
                  ],
                ),
              ),
            ),

            // ================= BOTTOM NAVIGATION =================
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Color(0xFF11151F),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                
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

  // ================= STAT CARD =================
  Widget statCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF11151F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [

          Text(
            title,
            style: TextStyle(
              color: Colors.grey,
              letterSpacing: 2,
              fontSize: 11,
            ),
          ),

          SizedBox(height: 12),

          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= SETTINGS TILE =================
  Widget settingsTile({
    required IconData icon,
    required String title,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF11151F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [

          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.deepPurple,
            ),
          ),

          SizedBox(width: 18),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ),

          Icon(
            Icons.chevron_right,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  // ================= NAV ITEM =================
  Widget navItem({
    required IconData icon,
    required String label,
    bool selected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [

        Icon(
          icon,
          color: selected
              ? Colors.deepPurple
              : Colors.grey,
        ),

        SizedBox(height: 5),

        Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.deepPurple
                : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}