import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_profile_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_home_screen.dart';
import '../../services/ride_service.dart';

class DriverRidePostScreen extends StatefulWidget {
  @override
  State<DriverRidePostScreen> createState() => _DriverRidePostScreenState();
}

class _DriverRidePostScreenState extends State<DriverRidePostScreen> {
  int currentIndex = 1;
  final _supabase = Supabase.instance.client;

  final fromController = TextEditingController();
  final toController = TextEditingController();
  final priceController = TextEditingController();
  final seatsController = TextEditingController();
  final timeController = TextEditingController();

  bool isLoading = false;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  Future<void> postRide() async {
    if (fromController.text.isEmpty ||
        toController.text.isEmpty ||
        priceController.text.isEmpty ||
        seatsController.text.isEmpty ||
        timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text("Fill all fields")),
      );
      return;
    }

    final driverDoc = await _supabase
        .from('profiles')
        .select()
        .eq('id', _currentUserId)
        .maybeSingle();

    if (driverDoc?['is_verified'] != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: Colors.orange,
            content: Text("Verify your account first")),
      );
      return;
    }

    setState(() => isLoading = true);

    await RideService.addRide(
      from: fromController.text,
      to: toController.text,
      time: timeController.text,
      price: priceController.text,
      driverId: _currentUserId,
      driverName: driverDoc?['name'] ?? '',
      vehicleModel: driverDoc?['vehicle_model'] ?? 'Economy',
      seats: int.parse(seatsController.text),
    );

    setState(() => isLoading = false);

    fromController.clear();
    toController.clear();
    priceController.clear();
    seatsController.clear();
    timeController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(backgroundColor: Colors.green, content: Text("Ride Posted Successfully")),
    );
  }

  Widget buildRideCard(dynamic ride) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase
          .from('ride_requests')
          .select()
          .eq('ride_id', ride['id']),
      builder: (context, requestSnapshot) {
        bool isBooked = false;
        dynamic request;

        if (requestSnapshot.hasData && requestSnapshot.data!.isNotEmpty) {
          isBooked = true;
          request = requestSnapshot.data!.first;
        }

        return GestureDetector(
          onTap: () => showRideDetails(ride, request),
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
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
                      child: Text(
                        "${ride['from']} → ${ride['to']}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: !isBooked
                            ? Colors.orange
                            : request['status'] == "accepted"
                                ? Colors.green
                                : request['status'] == "completed"
                                    ? Colors.deepPurple
                                    : Colors.blue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        !isBooked ? "OPEN" : request['status'].toString().toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text("Price: ${ride['price']} ETB",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 5),
                Text("Seats: ${ride['seats']}",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 18),
                if (!isBooked)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red),
                      onPressed: () async {
                        await RideService.deletePost(ride['id']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text("Ride cancelled")),
                        );
                      },
                      child: const Text("Cancel Ride"),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showRideDetails(dynamic ride, dynamic request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF050816),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text("${ride['from']} → ${ride['to']}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text("Price: ${ride['price']} ETB",
                  style: const TextStyle(color: Colors.grey, fontSize: 18)),
              const SizedBox(height: 10),
              Text("Seats: ${ride['seats']}",
                  style: const TextStyle(color: Colors.grey, fontSize: 18)),
              const SizedBox(height: 25),
              if (request != null) ...[
                const Text("Passenger Details",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 18),
                Text("Name: ${request['passenger_name']}",
                    style: const TextStyle(color: Colors.grey, fontSize: 18)),
                const SizedBox(height: 10),
                Text("Status: ${request['status']}",
                    style: const TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF050816),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Post Ride"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            textField(controller: fromController, hint: "From", icon: Icons.location_on),
            const SizedBox(height: 18),
            textField(controller: toController, hint: "To", icon: Icons.location_pin),
            const SizedBox(height: 18),
            textField(controller: priceController, hint: "Price", icon: Icons.attach_money),
            const SizedBox(height: 18),
            textField(controller: seatsController, hint: "Available Seats", icon: Icons.event_seat),
            const SizedBox(height: 18),
            textField(controller: timeController, hint: "Ride Time (e.g 4:30 PM)", icon: Icons.access_time),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: isLoading ? null : postRide,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Post Ride",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 35),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("My Posted Rides",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('posts')
                  .stream(primaryKey: ['id'])
                  .eq('driver_id', _currentUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString(),
                        style: const TextStyle(color: Colors.red)),
                  );
                }
                if (snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Text("No posted rides yet",
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                final rides = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    return buildRideCard(rides[index]);
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: const Color(0xFF050816),
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        onTap: (index) {
          setState(() => currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => DriverHomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => DriverRidePostScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => DriverEarningsScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => DriverProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Ride Post"),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: "Earnings"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        filled: true,
        fillColor: const Color(0xFF11151F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
