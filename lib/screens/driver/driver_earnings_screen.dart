import 'package:flutter/material.dart';
import 'driver_profile_screen.dart';
import 'driver_ride_post_screen.dart';
import 'driver_home_screen.dart';

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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // TOTAL EARNINGS
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Color(0xFF11151F),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                children: [

                  Text(
                    "TOTAL EARNINGS",
                    style: TextStyle(
                      color: Colors.grey,
                      letterSpacing: 2,
                    ),
                  ),

                  SizedBox(height: 15),

                  Text(
                    "\$0.00",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // TODAY
            earningsCard(
              title: "Today's Earnings",
              amount: "\$0.00",
            ),

            SizedBox(height: 15),

            // WEEK
            earningsCard(
              title: "Weekly Earnings",
              amount: "\$0.00",
            ),

            SizedBox(height: 15),

            // MONTH
            earningsCard(
              title: "Monthly Earnings",
              amount: "\$0.00",
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