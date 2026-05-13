import 'package:flutter/material.dart';
import 'passenger_profile_screen.dart';
import 'passenger_home_screen.dart';

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() => _PassengerActivityScreenState();
}

class _PassengerActivityScreenState extends State<PassengerActivityScreen> {
  @override
  Widget build(BuildContext context) {
    int currentIndex = 1;
    final List<Map<String, String>> trips = [
      {
        "from": "Dire Dawa",
        "to": "Harar",
        "date": "2026-05-10",
        "price": "120 ETB",
      },
      {
        "from": "Ayder",
        "to": "Kebele 03",
        "date": "2026-05-08",
        "price": "80 ETB",
      },
      {
        "from": "Main Station",
        "to": "Airport",
        "date": "2026-05-05",
        "price": "150 ETB",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      /*appBar: AppBar(
        title: const Text("Activity"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),*/
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car, color: Colors.purple),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${trip['from']} → ${trip['to']}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        trip['date']!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                Text(
                  trip['price']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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