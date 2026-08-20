import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRidesPage extends StatefulWidget {
  const AdminRidesPage({super.key});

  @override
  State<AdminRidesPage> createState() => _AdminRidesPageState();
}

class _AdminRidesPageState extends State<AdminRidesPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  String _statusFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _rides = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRides {
    return _rides.where((ride) {
      final matchesSearch = _searchQuery.isEmpty ||
          (ride['from'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ride['to'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (ride['driver_name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _statusFilter == 'all' || ride['status'] == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> _updateRideStatus(String rideId, String newStatus) async {
    await _supabase
        .from('posts')
        .update({'status': newStatus})
        .eq('id', rideId);
    _loadRides();
  }

  Future<void> _deleteRide(String rideId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Ride"),
        content: const Text("Are you sure you want to delete this ride?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.from('posts').delete().eq('id', rideId);
      _loadRides();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ride Management",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text("View and manage all posted rides",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by route or driver...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF11151F),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF11151F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButton<String>(
                  value: _statusFilter,
                  dropdownColor: const Color(0xFF11151F),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 'all', child: Text("All Status")),
                    DropdownMenuItem(
                        value: 'active', child: Text("Active")),
                    DropdownMenuItem(
                        value: 'full', child: Text("Full")),
                    DropdownMenuItem(
                        value: 'completed', child: Text("Completed")),
                  ],
                  onChanged: (value) {
                    setState(() => _statusFilter = value ?? 'all');
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: _loadRides,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRides.isEmpty
                    ? const Center(
                        child: Text("No rides found",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _filteredRides.length,
                        itemBuilder: (context, index) {
                          final ride = _filteredRides[index];
                          return _RideCard(
                            ride: ride,
                            onDelete: () => _deleteRide(ride['id']),
                            onUpdateStatus: (status) =>
                                _updateRideStatus(ride['id'], status),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onDelete;
  final Function(String) onUpdateStatus;

  const _RideCard({
    required this.ride,
    required this.onDelete,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] ?? 'active';
    final statusColor = status == 'active'
        ? const Color(0xFF34D399)
        : status == 'full'
            ? const Color(0xFFFBBF24)
            : const Color(0xFF60A5FA);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car,
                color: Color(0xFF7C4DFF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${ride['from']} → ${ride['to']}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text("Driver: ${ride['driver_name'] ?? 'Unknown'}",
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                    "${ride['price']} ETB • ${ride['seats']} seats • ${ride['time']}",
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(status.toString().toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            color: const Color(0xFF1A1F2E),
            onSelected: (value) {
              if (value == 'complete') {
                onUpdateStatus('completed');
              } else if (value == 'deactivate') {
                onUpdateStatus('active');
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              if (status != 'completed')
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF34D399), size: 18),
                      SizedBox(width: 8),
                      Text("Mark Completed"),
                    ],
                  ),
                ),
              if (status == 'full')
                const PopupMenuItem(
                  value: 'deactivate',
                  child: Row(
                    children: [
                      Icon(Icons.pause_circle,
                          color: Color(0xFFFBBF24), size: 18),
                      SizedBox(width: 8),
                      Text("Set Active"),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text("Delete",
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
