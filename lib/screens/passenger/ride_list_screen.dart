import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ride_service.dart';
import '../../theme/app_theme.dart';

class RideListScreen extends StatefulWidget {
  const RideListScreen({super.key});

  @override
  _RideListScreenState createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  void showRideConfirmation(Map<String, dynamic> posts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: 520,
          decoration: const BoxDecoration(
            color: Color(0xFF11151F),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const MicroLabel("Pickup", color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text(posts['from'],
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 25),
                const MicroLabel("Destination", color: AppColors.textMuted),
                const SizedBox(height: 8),
                Text(posts['to'],
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 35),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.directions_car,
                            size: 30, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(posts['vehicle_model'] ?? "Economy",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(
                                "${posts['time'] ?? 'Now'} • ${posts['seats'] ?? '4'} seats",
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("${posts['price']} ETB",
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                          const Text("Est. Price",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(posts['driver_name'] ?? "Driver",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await bookRide(
                        rideId: posts['id'],
                        driverId: posts['driver_id'],
                        rideData: posts,
                      );
                    },
                    child: const Text("Confirm Ride",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> bookRide({
    required String rideId,
    required String driverId,
    required Map<String, dynamic> rideData,
  }) async {
    if (_currentUserId.isEmpty) return;

    final passengerDoc = await _supabase
        .from('profiles')
        .select()
        .eq('id', _currentUserId)
        .maybeSingle();

    final driverDoc = await _supabase
        .from('profiles')
        .select()
        .eq('id', driverId)
        .maybeSingle();

    await RideService.addRideRequest({
      'driver_name': driverDoc?["name"],
      'driver_phone': driverDoc?["phone"],
      'driver_plate': driverDoc?["plate_number"],
      'passenger_phone': passengerDoc?["phone"],
      'ride_id': rideId,
      'driver_id': driverId,
      'passenger_id': _currentUserId,
      'passenger_name': passengerDoc?["name"],
      'from': rideData["from"],
      'to': rideData["to"],
      'price': rideData["price"],
      'status': 'pending',
    });

    await RideService.addNotification(
      userId: driverId,
      title: "New Ride Request",
      body: "${passengerDoc?["name"]} requested a ride",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          backgroundColor: Colors.green, content: Text("Ride request sent")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text("Where to?", style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                gradient: AppGradients.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() => searchQuery = value.toLowerCase());
                },
                decoration: InputDecoration(
                  hintText: "Search destination...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  icon: Icon(Icons.location_on, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      searchController.clear();
                      setState(() => searchQuery = "");
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: RideService.getRides(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text("No rides available",
                            style: TextStyle(color: Colors.white)));
                  }

                  final rides = snapshot.data!;
                  final filteredRides = rides.where((posts) {
                    final from = posts['from'].toString().toLowerCase();
                    final to = posts['to'].toString().toLowerCase();
                    return from.contains(searchQuery) ||
                        to.contains(searchQuery);
                  }).toList();

                  if (filteredRides.isEmpty) {
                    return const Center(
                        child: Text("No matching rides",
                            style: TextStyle(color: Colors.white)));
                  }

                  return ListView.builder(
                    itemCount: filteredRides.length,
                    itemBuilder: (context, index) {
                      final posts = filteredRides[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.2),
                              child: Icon(Icons.person, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${posts['from']} → ${posts['to']}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(posts['driver_name'] ?? "Driver",
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: posts['is_online'] == true
                                              ? Colors.green
                                              : Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          posts['is_online'] == true
                                              ? "ONLINE"
                                              : "OFFLINE",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Seats: ${posts['available_seats'] ?? 0}/${posts['total_seats'] ?? posts['seats'] ?? 0}",
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if ((posts['available_seats'] ?? 0) == 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text("FULL",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${posts['price']} ETB",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.gold,
                                        fontSize: 16)),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 92,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: posts['is_online'] == true &&
                                            (posts['available_seats'] ?? 0) > 0
                                        ? () => showRideConfirmation(posts)
                                        : null,
                                    child: const Text("Book"),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
