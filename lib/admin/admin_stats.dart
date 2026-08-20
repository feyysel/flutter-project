import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminStatsPage extends StatefulWidget {
  const AdminStatsPage({super.key});

  @override
  State<AdminStatsPage> createState() => _AdminStatsPageState();
}

class _AdminStatsPageState extends State<AdminStatsPage> {
  final _supabase = Supabase.instance.client;

  int totalUsers = 0;
  int totalDrivers = 0;
  int totalPassengers = 0;
  int pendingVerifications = 0;
  int totalRides = 0;
  int activeRides = 0;
  int completedRides = 0;
  int totalRequests = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final profiles = await _supabase.from('profiles').select('role, verification_status');
      final posts = await _supabase.from('posts').select('status');
      final history = await _supabase.from('ride_history').select('id');
      final requests = await _supabase.from('ride_requests').select('id, status');
      final pending = await _supabase
          .from('profiles')
          .select('id')
          .eq('verification_status', 'under_review');

      setState(() {
        totalUsers = profiles.length;
        totalDrivers = profiles.where((p) => p['role'] == 'driver').length;
        totalPassengers = profiles.where((p) => p['role'] == 'passenger').length;
        pendingVerifications = pending.length;
        totalRides = posts.length;
        activeRides = posts.where((p) => p['status'] == 'active').length;
        completedRides = history.length;
        totalRequests = requests.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Dashboard Overview",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: _loadStats,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Platform statistics and overview",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 28),
          LayoutGrid(
            columnCount: 4,
            children: [
              _StatCard(
                  title: "Total Users",
                  value: "$totalUsers",
                  icon: Icons.people,
                  color: const Color(0xFF7C4DFF)),
              _StatCard(
                  title: "Drivers",
                  value: "$totalDrivers",
                  icon: Icons.directions_car,
                  color: const Color(0xFF34D399)),
              _StatCard(
                  title: "Passengers",
                  value: "$totalPassengers",
                  icon: Icons.person,
                  color: const Color(0xFFF2C14E)),
              _StatCard(
                  title: "Pending Verifications",
                  value: "$pendingVerifications",
                  icon: Icons.verified_user,
                  color: const Color(0xFFF87171)),
            ],
          ),
          const SizedBox(height: 20),
          LayoutGrid(
            columnCount: 4,
            children: [
              _StatCard(
                  title: "Total Rides",
                  value: "$totalRides",
                  icon: Icons.map,
                  color: const Color(0xFF8B5CF6)),
              _StatCard(
                  title: "Active Rides",
                  value: "$activeRides",
                  icon: Icons.radio_button_checked,
                  color: const Color(0xFF34D399)),
              _StatCard(
                  title: "Completed Rides",
                  value: "$completedRides",
                  icon: Icons.check_circle,
                  color: const Color(0xFF60A5FA)),
              _StatCard(
                  title: "Ride Requests",
                  value: "$totalRequests",
                  icon: Icons.receipt_long,
                  color: const Color(0xFFFBBF24)),
            ],
          ),
        ],
      ),
    );
  }
}

class LayoutGrid extends StatelessWidget {
  final int columnCount;
  final List<Widget> children;

  const LayoutGrid({
    super.key,
    required this.columnCount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveColumns = constraints.maxWidth < 600
            ? 1
            : constraints.maxWidth < 900
                ? 2
                : columnCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: children.map((child) {
            return SizedBox(
              width: (constraints.maxWidth -
                      (responsiveColumns - 1) * 16) /
                  responsiveColumns,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
