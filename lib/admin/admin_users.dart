import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .order('name');
      setState(() {
        _users = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = _searchQuery.isEmpty ||
          (user['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user['phone'] ?? '').contains(_searchQuery);
      final matchesRole =
          _roleFilter == 'all' || user['role'] == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  Future<void> _toggleVerification(String userId, bool currentStatus) async {
    await _supabase.from('profiles').update({
      'is_verified': !currentStatus,
      'verification_status': !currentStatus ? 'verified' : 'none',
    }).eq('id', userId);
    _loadUsers();
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure you want to delete this user?"),
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
      try {
        await _supabase.from('profiles').delete().eq('id', userId);
        _loadUsers();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
          );
        }
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    await _supabase.from('profiles').update({'role': newRole}).eq('id', userId);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("User Management",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text("View, manage, and verify all users",
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by name or phone...",
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
                  value: _roleFilter,
                  dropdownColor: const Color(0xFF11151F),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                        value: 'all', child: Text("All Roles")),
                    DropdownMenuItem(
                        value: 'driver', child: Text("Drivers")),
                    DropdownMenuItem(
                        value: 'passenger', child: Text("Passengers")),
                  ],
                  onChanged: (value) {
                    setState(() => _roleFilter = value ?? 'all');
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: _loadUsers,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text("No users found",
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _UserCard(
                            user: user,
                            onToggleVerification: () => _toggleVerification(
                                user['id'], user['is_verified'] ?? false),
                            onDelete: () => _deleteUser(user['id']),
                            onChangeRole: (newRole) =>
                                _updateUserRole(user['id'], newRole),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleVerification;
  final VoidCallback onDelete;
  final Function(String) onChangeRole;

  const _UserCard({
    required this.user,
    required this.onToggleVerification,
    required this.onDelete,
    required this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = user['is_verified'] ?? false;
    final role = user['role'] ?? 'passenger';
    final verificationStatus = user['verification_status'] ?? 'none';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified
              ? const Color(0xFF34D399).withOpacity(0.3)
              : verificationStatus == 'under_review'
                  ? const Color(0xFFFBBF24).withOpacity(0.3)
                  : const Color(0x14FFFFFF),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF1A1F2E),
            backgroundImage: user['profile_image'] != null &&
                    user['profile_image'] != ''
                ? NetworkImage(user['profile_image'])
                : null,
            child: user['profile_image'] == null || user['profile_image'] == ''
                ? Text(
                    (user['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user['name'] ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role == 'driver'
                            ? const Color(0xFF7C4DFF).withOpacity(0.2)
                            : const Color(0xFFF2C14E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(role.toUpperCase(),
                          style: TextStyle(
                              color: role == 'driver'
                                  ? const Color(0xFF7C4DFF)
                                  : const Color(0xFFF2C14E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(user['phone'] ?? '',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF34D399).withOpacity(0.2)
                        : verificationStatus == 'under_review'
                            ? const Color(0xFFFBBF24).withOpacity(0.2)
                            : verificationStatus == 'rejected'
                                ? const Color(0xFFF87171).withOpacity(0.2)
                                : const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isVerified
                        ? "VERIFIED"
                        : verificationStatus
                            .toString()
                            .toUpperCase(),
                    style: TextStyle(
                      color: isVerified
                          ? const Color(0xFF34D399)
                          : verificationStatus == 'under_review'
                              ? const Color(0xFFFBBF24)
                              : verificationStatus == 'rejected'
                                  ? const Color(0xFFF87171)
                                  : Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            color: const Color(0xFF1A1F2E),
            onSelected: (value) {
              if (value == 'verify') {
                onToggleVerification();
              } else if (value == 'delete') {
                onDelete();
              } else if (value == 'make_driver') {
                onChangeRole('driver');
              } else if (value == 'make_passenger') {
                onChangeRole('passenger');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'verify',
                child: Row(
                  children: [
                    Icon(
                        isVerified ? Icons.cancel : Icons.verified,
                        color: isVerified ? Colors.red : Colors.green,
                        size: 18),
                    const SizedBox(width: 8),
                    Text(isVerified ? "Revoke Verification" : "Verify User"),
                  ],
                ),
              ),
              if (role == 'passenger')
                const PopupMenuItem(
                  value: 'make_driver',
                  child: Row(
                    children: [
                      Icon(Icons.directions_car,
                          color: Color(0xFF7C4DFF), size: 18),
                      SizedBox(width: 8),
                      Text("Make Driver"),
                    ],
                  ),
                ),
              if (role == 'driver')
                const PopupMenuItem(
                  value: 'make_passenger',
                  child: Row(
                    children: [
                      Icon(Icons.person,
                          color: Color(0xFFF2C14E), size: 18),
                      SizedBox(width: 8),
                      Text("Make Passenger"),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text("Delete User",
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
