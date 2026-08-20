import 'package:flutter/material.dart';
import 'passenger_profile_screen.dart';
import 'passenger_home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ride_service.dart';

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() =>
      _PassengerActivityScreenState();
}

class _PassengerActivityScreenState extends State<PassengerActivityScreen> {
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    int currentIndex = 1;

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Activity", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF11151F),
        elevation: 10,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('ride_requests')
            .stream(primaryKey: ['id'])
            .eq('passenger_id', _currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No ride activity yet",
                  style: TextStyle(color: Colors.white)),
            );
          }

          final rides = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];

              Color statusColor = Colors.orange;
              if (ride['status'] == "accepted") statusColor = Colors.green;
              if (ride['status'] == "completed") statusColor = Colors.deepPurple;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF11151F),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text("${ride['from']} → ${ride['to']}",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            ride['status'].toString().toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text("Price: ${ride['price']} ETB",
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text("Passenger: ${ride['passenger_name']}",
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 10),
                    if (ride['status'] == "pending")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Waiting for driver acceptance",
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () async {
                                await RideService.deleteRideRequest(ride['id']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text("Ride request cancelled")),
                                );
                              },
                              child: const Text("Cancel Request"),
                            ),
                          ),
                        ],
                      ),
                    if (ride['status'] == "accepted")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Driver accepted your ride",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Driver Details",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 10),
                                Text("Name: ${ride['driver_name'] ?? ''}",
                                    style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text("Phone: ${ride['driver_phone'] ?? ''}",
                                    style: const TextStyle(color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text(
                                    "Plate Number: ${ride['driver_plate'] ?? ''}",
                                    style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (ride['status'] == "completed")
                      const Text("Ride completed successfully",
                          style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: const Color(0xFF11151F),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => PassengerHomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => PassengerActivityScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => PassengerProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: "Activity"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
