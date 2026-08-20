import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminVerificationsPage extends StatefulWidget {
  const AdminVerificationsPage({super.key});

  @override
  State<AdminVerificationsPage> createState() =>
      _AdminVerificationsPageState();
}

class _AdminVerificationsPageState extends State<AdminVerificationsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('verification_status', 'under_review')
          .order('name');
      setState(() {
        _pendingUsers = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveVerification(String userId) async {
    await _supabase.from('profiles').update({
      'is_verified': true,
      'verification_status': 'verified',
    }).eq('id', userId);
    _loadPending();
  }

  Future<void> _rejectVerification(String userId) async {
    await _supabase.from('profiles').update({
      'is_verified': false,
      'verification_status': 'rejected',
    }).eq('id', userId);
    _loadPending();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Verification Approvals",
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    SizedBox(height: 8),
                    Text("Review and approve driver verification documents",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: _loadPending,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pendingUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user,
                                size: 64,
                                color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text("No pending verifications",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 18)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _pendingUsers.length,
                        itemBuilder: (context, index) {
                          final user = _pendingUsers[index];
                          return _VerificationCard(
                            user: user,
                            onApprove: () =>
                                _approveVerification(user['id']),
                            onReject: () =>
                                _rejectVerification(user['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFFBBF24).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF1A1F2E),
                backgroundImage: user['profile_photo_url'] != null &&
                        user['profile_photo_url'] != ''
                    ? NetworkImage(user['profile_photo_url'])
                    : null,
                child: user['profile_photo_url'] == null ||
                        user['profile_photo_url'] == ''
                    ? Text(
                        (user['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'] ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text("Phone: ${user['phone'] ?? 'N/A'}",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 13)),
                    Text("Plate: ${user['plate_number'] ?? 'N/A'}",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("UNDER REVIEW",
                    style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Submitted Documents",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user['profile_photo_url'] != null &&
                  user['profile_photo_url'] != '')
                _DocumentChip(
                    label: "Profile Photo", url: user['profile_photo_url']),
              if (user['id_front_url'] != null && user['id_front_url'] != '')
                _DocumentChip(label: "ID Front", url: user['id_front_url']),
              if (user['id_back_url'] != null && user['id_back_url'] != '')
                _DocumentChip(label: "ID Back", url: user['id_back_url']),
              if (user['license_url'] != null && user['license_url'] != '')
                _DocumentChip(
                    label: "Driver License", url: user['license_url']),
              if (user['car_photo_url'] != null && user['car_photo_url'] != '')
                _DocumentChip(label: "Car Photo", url: user['car_photo_url']),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34D399),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Approve",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF87171),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onReject,
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text("Reject",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  final String label;
  final String url;

  const _DocumentChip({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.description, size: 16, color: Colors.white),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: const Color(0xFF1A1F2E),
      side: const BorderSide(color: Color(0x14FFFFFF)),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: const Color(0xFF11151F),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: const Color(0xFF1A1F2E),
                          child: const Center(
                            child: Text("Failed to load image",
                                style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
