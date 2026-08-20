import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        title: const Text("Trip History", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF11151F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('ride_history')
            .stream(primaryKey: ['id'])
            .eq('driver_id', userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rides = snapshot.data!;

          if (rides.isEmpty) {
            return const Center(
              child: Text("No completed trips", style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF11151F),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 8),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${ride['from']} → ${ride['to']}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text("Passenger: ${ride['passenger_name'] ?? ''}",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text("Earned: ${ride['price']} ETB",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    const Text("COMPLETED",
                        style: TextStyle(
                            color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
