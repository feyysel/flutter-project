import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _DriverDoc {
  final String key;
  final String label;
  final String? url;
  final IconData icon;

  const _DriverDoc({
    required this.key,
    required this.label,
    required this.icon,
    this.url,
  });

  bool get exists => url != null && url!.isNotEmpty;
}

List<_DriverDoc> _buildDocs(Map<String, dynamic> user) {
  String? s(String? v) =>
      (v == null || v.toString().isEmpty) ? null : v.toString();
  return [
    _DriverDoc(
      key: 'profile_photo',
      label: 'Profile Photo',
      icon: Icons.person_outline,
      url: s(user['profile_photo_url']),
    ),
    _DriverDoc(
      key: 'id_front',
      label: 'ID Card — Front',
      icon: Icons.badge_outlined,
      url: s(user['id_front_url']),
    ),
    _DriverDoc(
      key: 'id_back',
      label: 'ID Card — Back',
      icon: Icons.badge_outlined,
      url: s(user['id_back_url']),
    ),
    _DriverDoc(
      key: 'license',
      label: "Driver's License",
      icon: Icons.workspace_premium_outlined,
      url: s(user['license_url']),
    ),
    _DriverDoc(
      key: 'car_photo',
      label: 'Vehicle Photo',
      icon: Icons.directions_car_outlined,
      url: s(user['car_photo_url']),
    ),
  ];
}

class AdminVerificationsPage extends StatefulWidget {
  const AdminVerificationsPage({super.key});

  @override
  State<AdminVerificationsPage> createState() => _AdminVerificationsPageState();
}

class _AdminVerificationsPageState extends State<AdminVerificationsPage> {
  final _supabase = Supabase.instance.client;
  static const int _pageSize = 20;

  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _verifiedDrivers = [];
  int? _pendingTotal;
  int? _verifiedTotal;
  bool _pendingHasMore = false;
  bool _verifiedHasMore = false;
  bool _pendingLoadingMore = false;
  bool _verifiedLoadingMore = false;
  bool _isLoading = true;
  String? _error;
  bool _showVerifiedTab = false;

  final _pendingScrollController = ScrollController();
  final _verifiedScrollController = ScrollController();
  final _verifiedSearchController = TextEditingController();
  String _verifiedSearchQuery = "";
  Timer? _searchDebounce;
  int _pendingReqId = 0;
  int _verifiedReqId = 0;

  @override
  void initState() {
    super.initState();
    _pendingScrollController.addListener(() {
      if (_pendingScrollController.position.extentAfter < 400) {
        _loadPendingPage();
      }
    });
    _verifiedScrollController.addListener(() {
      if (_verifiedScrollController.position.extentAfter < 400) {
        _loadVerifiedPage();
      }
    });
    _refreshAll();
  }

  @override
  void dispose() {
    _pendingScrollController.dispose();
    _verifiedScrollController.dispose();
    _verifiedSearchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadPendingPage(reset: true),
      _loadVerifiedPage(reset: true),
    ]);
  }

  Future<void> _loadPendingPage({bool reset = false}) async {
    if (!reset) {
      if (_pendingLoadingMore || !_pendingHasMore || _isLoading) return;
      setState(() => _pendingLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _pendingUsers.clear();
        _pendingTotal = null;
        _pendingHasMore = true;
        _pendingLoadingMore = false;
      });
    }
    final reqId = ++_pendingReqId;
    try {
      final from = reset ? 0 : _pendingUsers.length;
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('verification_status', 'under_review')
          .order('created_at')
          .range(from, from + _pageSize - 1)
          .count(CountOption.exact);
      if (!mounted || reqId != _pendingReqId) return;
      final page = List<Map<String, dynamic>>.from(res.data);
      setState(() {
        if (reset) {
          _pendingUsers = page;
        } else {
          _pendingUsers.addAll(page);
        }
        _pendingTotal = res.count ?? _pendingUsers.length;
        _pendingHasMore =
            page.isNotEmpty && _pendingUsers.length < (_pendingTotal ?? 0);
        _error = null;
      });
    } catch (e) {
      if (mounted && reset) setState(() => _error = e.toString());
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _pendingLoadingMore = false;
      });
    }
  }

  Future<void> _loadVerifiedPage({bool reset = false}) async {
    if (!reset) {
      if (_verifiedLoadingMore || !_verifiedHasMore || _isLoading) return;
      setState(() => _verifiedLoadingMore = true);
    } else {
      setState(() {
        _verifiedHasMore = true;
        _verifiedLoadingMore = false;
      });
    }
    final reqId = ++_verifiedReqId;
    try {
      final query = _supabase
          .from('profiles')
          .select()
          .eq('role', 'driver')
          .eq('verification_status', 'verified');
      final searched = _verifiedSearchQuery.trim();
      final filtered = (reset && searched.isNotEmpty)
          ? query.or(
              'name.ilike.*${_sanitizeSearch(searched)}*,'
              'phone.ilike.*${_sanitizeSearch(searched)}*,'
              'plate_number.ilike.*${_sanitizeSearch(searched)}*',
            )
          : query;
      final from = reset ? 0 : _verifiedDrivers.length;
      final res = await filtered
          .order('name')
          .range(from, from + _pageSize - 1)
          .count(CountOption.exact);
      if (!mounted || reqId != _verifiedReqId) return;
      final page = List<Map<String, dynamic>>.from(res.data);
      setState(() {
        if (reset) {
          _verifiedDrivers = page;
        } else {
          _verifiedDrivers.addAll(page);
        }
        _verifiedTotal = res.count ?? _verifiedDrivers.length;
        _verifiedHasMore =
            page.isNotEmpty && _verifiedDrivers.length < (_verifiedTotal ?? 0);
      });
    } catch (_) {}
    if (mounted) setState(() => _verifiedLoadingMore = false);
  }

  /// Strips characters that would break PostgREST's .or() filter syntax.
  String _sanitizeSearch(String input) =>
      input.replaceAll(RegExp(r'[,()%*]'), ' ').trim();

  void _onVerifiedSearchChanged(String value) {
    setState(() => _verifiedSearchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      () => _loadVerifiedPage(reset: true),
    );
  }

  void _clearVerifiedSearch() {
    _searchDebounce?.cancel();
    _verifiedSearchController.clear();
    setState(() => _verifiedSearchQuery = "");
    _loadVerifiedPage(reset: true);
  }

  /// Updates verification state through the SECURITY DEFINER RPC (bypasses
  /// RLS entirely). Falls back to a direct update if the RPC doesn't exist yet.
  /// Returns true only if the database row actually changed (read-back check).
  Future<bool> _applyVerification({
    required String userId,
    required String status,
    String? reason,
    List<String>? declinedKeys,
  }) async {
    final isVerify = status == 'verified';
    final isReject = status == 'rejected';

    try {
      if (isVerify) {
        await _supabase.rpc(
          'admin_verify_driver',
          params: {'p_driver_id': userId},
        );
      } else if (isReject) {
        await _supabase.rpc(
          'admin_decline_driver',
          params: {
            'p_driver_id': userId,
            'p_reason': reason ?? '',
            'p_docs': declinedKeys ?? <String>[],
          },
        );
      } else {
        await _supabase.rpc(
          'admin_revoke_driver',
          params: {'p_driver_id': userId},
        );
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();
      final rpcMissing =
          msg.contains('not found') ||
          msg.contains('could not find the function') ||
          msg.contains('does not exist') ||
          msg.contains('404') ||
          msg.contains('42883');
      if (!rpcMissing) rethrow;

      // RPC not deployed — fall back to direct update + RLS policies.
      final data = <String, dynamic>{
        'is_verified': isVerify,
        'verification_status': status,
      };
      try {
        if (isVerify || !isReject) {
          data['rejection_reason'] = null;
          data['rejected_documents'] = <String>[];
        } else {
          data['rejection_reason'] = reason;
          data['rejected_documents'] = declinedKeys ?? <String>[];
        }
        await _supabase.from('profiles').update(data).eq('id', userId);
      } catch (e2) {
        final m2 = e2.toString().toLowerCase();
        final missingOptional =
            m2.contains('rejection_reason') ||
            m2.contains('rejected_documents');
        data.remove('rejection_reason');
        data.remove('rejected_documents');
        if (!missingOptional) rethrow;
        await _supabase.from('profiles').update(data).eq('id', userId);
      }
    }

    // Read-back: confirm the change really landed in the database.
    final row = await _supabase
        .from('profiles')
        .select('verification_status, is_verified')
        .eq('id', userId)
        .maybeSingle();
    return row != null &&
        row['verification_status'] == status &&
        row['is_verified'] == isVerify;
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('NOT_ADMIN')) {
      return 'Your account is not flagged as admin.\n\n'
          "Run: UPDATE profiles SET is_admin = TRUE WHERE phone = '<your admin phone>';";
    }
    if (msg.contains('DRIVER_NOT_FOUND')) {
      return 'Driver row not found in database.';
    }
    if (msg.contains('row-level security') ||
        msg.contains('permission denied')) {
      return 'Blocked by database rules.\n\n'
          'Run supabase/admin_verification_fix.sql in the Supabase SQL Editor.';
    }
    return 'Failed: $msg';
  }

  Future<void> _approveVerification(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Approve Driver?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You have checked every detail of ${user['name'] ?? 'this driver'}.\n'
          '\nThis will grant them full driver access to post rides.',
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF34D399),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Yes, Verify'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final ok = await _applyVerification(
        userId: user['id'],
        status: 'verified',
      );

      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFFBBF24),
              duration: const Duration(seconds: 8),
              content: const Text(
                'The update did not stick. Run supabase/admin_verification_fix.sql '
                'in the Supabase SQL Editor, make sure your admin phone is set in '
                "step 3, then try again.",
              ),
            ),
          );
        }
        _refreshAll();
        return;
      }

      try {
        await _supabase.from('notifications').insert({
          'user_id': user['id'],
          'title': 'Account Verified',
          'body':
              'Congratulations! Your documents were reviewed and approved. You can now post rides.',
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF34D399),
            content: Text(
              '${user['name'] ?? 'Driver'} is now verified and can post rides',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF87171),
            content: Text(_friendlyError(e)),
          ),
        );
      }
    }
    _refreshAll();
  }

  Future<void> _revokeVerification(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Revoke Verification?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '${user['name'] ?? 'This driver'} will lose access to post rides '
          'until they submit documents again.',
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.gpp_bad_rounded, size: 18),
            label: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final ok = await _applyVerification(userId: user['id'], status: 'none');

      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFFBBF24),
              duration: const Duration(seconds: 8),
              content: const Text(
                'The update did not stick. Run supabase/admin_verification_fix.sql '
                'in the Supabase SQL Editor, then try again.',
              ),
            ),
          );
        }
        _refreshAll();
        return;
      }

      try {
        await _supabase.from('notifications').insert({
          'user_id': user['id'],
          'title': 'Verification Revoked',
          'body':
              'Your driver verification was revoked. Please re-submit your documents to regain posting access.',
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF87171),
            content: Text('${user['name'] ?? 'Driver'} verification revoked'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF87171),
            content: Text(_friendlyError(e)),
          ),
        );
      }
    }
    _refreshAll();
  }

  Future<void> _openDeclineSheet(Map<String, dynamic> user) async {
    final result = await showModalBottomSheet<_DeclineResult>(
      context: context,
      backgroundColor: const Color(0xFF11151F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DeclineSheet(user: user),
    );
    if (result == null) return;

    try {
      final ok = await _applyVerification(
        userId: user['id'],
        status: 'rejected',
        reason: result.reason,
        declinedKeys: result.declinedKeys,
      );

      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFFBBF24),
              duration: const Duration(seconds: 8),
              content: const Text(
                'The update did not stick. Run supabase/admin_verification_fix.sql '
                'in the Supabase SQL Editor, then try again.',
              ),
            ),
          );
        }
        _refreshAll();
        return;
      }

      final docNames = _buildDocs(user)
          .where((d) => result.declinedKeys.contains(d.key))
          .map((d) => d.label)
          .join(', ');

      try {
        await _supabase.from('notifications').insert({
          'user_id': user['id'],
          'title': 'Verification Declined',
          'body':
              'Your verification was declined. '
              '${docNames.isEmpty ? '' : 'Declined document(s): $docNames. '}'
              'Reason: ${result.reason} Please re-upload the highlighted documents.',
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF87171),
            content: Text('Declined: ${result.declinedLabels.join(', ')}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFF87171),
            content: Text(_friendlyError(e)),
          ),
        );
      }
    }
    _refreshAll();
  }

  void _openFullReview(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DriverReviewPage(
          user: user,
          onApprove: () => _approveVerification(user),
          onDecline: () => _openDeclineSheet(user),
        ),
      ),
    );
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
                    Text(
                      "Verification Approvals",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Check every detail, photo and credential before approving",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: _refreshAll,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            style: SegmentedButton.styleFrom(
              backgroundColor: const Color(0xFF161B26),
              foregroundColor: Colors.grey,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: const Color(0xFF7C4DFF),
              side: BorderSide(color: Colors.white.withOpacity(0.10)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.hourglass_top_rounded, size: 18),
                label: Text(
                  "Pending (${_pendingTotal ?? _pendingUsers.length})",
                ),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.verified_user_rounded, size: 18),
                label: Text(
                  "Verified Drivers (${_verifiedTotal ?? _verifiedDrivers.length})",
                ),
              ),
            ],
            selected: {_showVerifiedTab},
            onSelectionChanged: (selection) =>
                setState(() => _showVerifiedTab = selection.first),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading && !_showVerifiedTab
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 56,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : _showVerifiedTab
                ? _buildVerifiedList()
                : _buildPendingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    if (_pendingUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user,
              size: 64,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              "No pending verifications",
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }
    final footerNeeded = _pendingLoadingMore || _pendingHasMore;
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView.builder(
        controller: _pendingScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _pendingUsers.length + (footerNeeded ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _pendingUsers.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: _pendingLoadingMore
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        "Showing all ${_pendingTotal ?? _pendingUsers.length}",
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
              ),
            );
          }
          final user = _pendingUsers[index];
          return _VerificationCard(
            user: user,
            onOpenReview: () => _openFullReview(user),
            onApprove: () => _approveVerification(user),
            onReject: () => _openDeclineSheet(user),
          );
        },
      ),
    );
  }

  Widget _buildVerifiedList() {
    final searching = _verifiedSearchQuery.trim().isNotEmpty;
    final footerNeeded = _verifiedLoadingMore || _verifiedHasMore;

    return Column(
      children: [
        TextField(
          controller: _verifiedSearchController,
          onChanged: _onVerifiedSearchChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Search by name, phone or plate…",
            hintStyle: const TextStyle(color: Color(0xFF5C6470)),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF60A5FA),
            ),
            suffixIcon: _verifiedSearchQuery.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: _clearVerifiedSearch,
                  ),
            filled: true,
            fillColor: const Color(0xFF161B26),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _verifiedDrivers.isEmpty && !_verifiedLoadingMore
              ? RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                searching
                                    ? Icons.search_off_rounded
                                    : Icons.directions_car_filled,
                                size: 52,
                                color: Colors.grey.withOpacity(0.35),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                searching
                                    ? "No drivers match \"${_verifiedSearchQuery.trim()}\""
                                    : "No verified drivers yet",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshAll,
                  child: ListView.builder(
                    controller: _verifiedScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _verifiedDrivers.length + (footerNeeded ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _verifiedDrivers.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: _verifiedLoadingMore
                                ? const SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    "Showing all "
                                    "${_verifiedTotal ?? _verifiedDrivers.length}"
                                    "${searching ? ' results' : ' drivers'}",
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                          ),
                        );
                      }
                      final driver = _verifiedDrivers[index];
                      return _VerifiedDriverCard(
                        driver: driver,
                        onRevoke: () => _revokeVerification(driver),
                        onOpenDetail: () => _openVerifiedDriverDetail(driver),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _openVerifiedDriverDetail(Map<String, dynamic> driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DriverReviewPage(
          user: driver,
          readOnly: true,
          onRevoke: () => _revokeVerification(driver),
        ),
      ),
    );
  }
}

// ============================================================
// LIST CARD
// ============================================================
class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onOpenReview;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.user,
    required this.onOpenReview,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final docs = _buildDocs(user);
    final missing = docs.where((d) => !d.exists).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: docs.firstWhere((d) => d.key == 'profile_photo').exists
                    ? () => _showFullScreenImage(
                        context,
                        docs.firstWhere((d) => d.key == 'profile_photo').url!,
                      )
                    : null,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF1A1F2E),
                  backgroundImage: docs[0].exists
                      ? NetworkImage(docs[0].url!)
                      : null,
                  child: !docs[0].exists
                      ? Text(
                          (user['name'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user['phone'] ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.pin_drop_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Plate: ${user['plate_number'] ?? 'N/A'}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "UNDER REVIEW",
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Submitted Documents — tap any photo to inspect closely",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          if (missing > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "$missing document(s) missing!",
                style: const TextStyle(color: Color(0xFFFBBF24), fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: docs.length,
            itemBuilder: (context, i) => _DocThumb(doc: docs[i]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFF60A5FA).withOpacity(0.6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onOpenReview,
                  icon: const Icon(
                    Icons.plagiarism_outlined,
                    color: Color(0xFF60A5FA),
                    size: 19,
                  ),
                  label: const Text(
                    "Inspect Full Details",
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34D399),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    "Verify",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF87171),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onReject,
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    "Decline",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocThumb extends StatelessWidget {
  final _DriverDoc doc;
  const _DocThumb({required this.doc});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: doc.exists ? () => _showFullScreenImage(context, doc.url!) : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: doc.exists
                ? Colors.white.withOpacity(0.15)
                : Colors.redAccent.withOpacity(0.5),
          ),
          color: const Color(0xFF1A1F2E),
        ),
        clipBehavior: Clip.antiAlias,
        child: doc.exists
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    doc.url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.65),
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: 4,
                      ),
                      child: Text(
                        doc.label.split('—')[0].trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.zoom_in, size: 16, color: Colors.white70),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(doc.icon, color: Colors.redAccent.withOpacity(0.7)),
                  const SizedBox(height: 4),
                  const Text(
                    "Missing",
                    style: TextStyle(color: Colors.redAccent, fontSize: 10),
                  ),
                ],
              ),
      ),
    );
  }
}

// ============================================================
// FULL REVIEW PAGE — every detail & credential
// ============================================================
class _DriverReviewPage extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final bool readOnly;
  final VoidCallback? onRevoke;

  const _DriverReviewPage({
    required this.user,
    this.onApprove,
    this.onDecline,
    this.readOnly = false,
    this.onRevoke,
  });

  String _fmtDate(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null || d.year <= 1970) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final amPm = d.hour >= 12 ? 'PM' : 'AM';
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}'
        ' • ${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final docs = _buildDocs(user);

    return Scaffold(
      backgroundColor: const Color(0xFF0C101B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF11151F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(readOnly ? "Verified Driver" : "Driver Inspection"),
        actions: [
          readOnly
              ? Chip(
                  backgroundColor: const Color(0xFF34D399).withOpacity(0.2),
                  label: const Text(
                    "VERIFIED",
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Chip(
                  backgroundColor: const Color(0xFFFBBF24).withOpacity(0.2),
                  label: const Text(
                    "UNDER REVIEW",
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Identity header ----
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11151F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF1A1F2E),
                        backgroundImage: docs[0].exists
                            ? NetworkImage(docs[0].url!)
                            : null,
                        child: !docs[0].exists
                            ? const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['name'] ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "User ID: ${user['id']}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ---- Credentials grid ----
                const Text(
                  "ACCOUNT CREDENTIALS",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 700
                        ? 4
                        : (c.maxWidth > 480 ? 2 : 1);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: cols == 1 ? 4 : 2.6,
                      ),
                      itemCount: 5,
                      itemBuilder: (context, i) {
                        final items = [
                          (
                            'Phone Number',
                            user['phone'] ?? 'N/A',
                            Icons.phone_android_rounded,
                          ),
                          (
                            'Plate Number',
                            user['plate_number'] ?? 'N/A',
                            Icons.pin_drop_rounded,
                          ),
                          (
                            'Role',
                            (user['role'] ?? '').toString().toUpperCase(),
                            Icons.badge_rounded,
                          ),
                          (
                            'Submitted At',
                            _fmtDate(user['updated_at'] ?? user['created_at']),
                            Icons.schedule_rounded,
                          ),
                          (
                            'Member Since',
                            _fmtDate(user['created_at']),
                            Icons.calendar_month_rounded,
                          ),
                        ][i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161B26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    items.$3,
                                    size: 15,
                                    color: const Color(0xFF60A5FA),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    items.$1.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10.5,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                items.$2,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 26),

                // ---- Documents ----
                const Text(
                  "DOCUMENT PHOTOS — click to zoom & inspect",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...docs.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _DocumentDetailCard(doc: d),
                  ),
                ),

                const SizedBox(height: 8),
                // ---- Decision bar ----
                if (!readOnly)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11151F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFBBF24).withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Final decision",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Verify only if every photo is clear and credentials match.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34D399),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onApprove?.call();
                          },
                          icon: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Verify Driver",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF87171),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            onDecline?.call();
                          },
                          icon: const Icon(
                            Icons.gpp_bad_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Decline…",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11151F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF34D399).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFF34D399),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Verified driver",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "This driver can post rides. All documents were approved.",
                                style: TextStyle(
                                  color: Colors.grey.withOpacity(0.9),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onRevoke != null) ...[
                          const SizedBox(width: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFF87171),
                              side: BorderSide(
                                color: const Color(0xFFF87171).withOpacity(0.5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              onRevoke!();
                            },
                            icon: const Icon(Icons.block_rounded, size: 17),
                            label: const Text("Revoke Access"),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentDetailCard extends StatelessWidget {
  final _DriverDoc doc;
  const _DocumentDetailCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: doc.exists
              ? Colors.white.withOpacity(0.07)
              : Colors.redAccent.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(doc.icon, size: 17, color: const Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Text(
                doc.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: doc.exists
                      ? const Color(0xFF34D399).withOpacity(0.15)
                      : const Color(0xFFF87171).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  doc.exists ? "SUBMITTED" : "MISSING",
                  style: TextStyle(
                    color: doc.exists
                        ? const Color(0xFF34D399)
                        : const Color(0xFFF87171),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!doc.exists)
            Container(
              height: 120,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                "This document was not uploaded",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            GestureDetector(
              onTap: () => _showFullScreenImage(context, doc.url!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        doc.url!,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const Center(child: CircularProgressIndicator()),
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text(
                            "Failed to load image",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.zoom_in,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 5),
                              Text(
                                "Zoom",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// FULL-SCREEN ZOOM VIEWER
// ============================================================
void _showFullScreenImage(BuildContext context, String url) {
  Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.96),
      pageBuilder: (_, __, ___) => _FullScreenPhotoViewer(url: url),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _FullScreenPhotoViewer extends StatefulWidget {
  final String url;
  const _FullScreenPhotoViewer({required this.url});

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  final _transform = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final pos = _doubleTapDetails?.localPosition;
    if (_transform.value != Matrix4.identity()) {
      _transform.value = Matrix4.identity();
    } else {
      const scale = 2.5;
      if (pos != null) {
        _transform.value = Matrix4.identity()
          ..translateByDouble(pos.dx * (scale - 1), pos.dy * (scale - 1), 0, 1)
          ..scaleByDouble(scale, scale, 1, 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: (d) => _doubleTapDetails = d,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transform,
              panEnabled: true,
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Image.network(widget.url, fit: BoxFit.contain),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.15),
                  ),
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DECLINE SHEET — pick exactly which documents failed
// ============================================================
class _DeclineResult {
  final List<String> declinedKeys;
  final List<String> declinedLabels;
  final String reason;
  const _DeclineResult(this.declinedKeys, this.declinedLabels, this.reason);
}

class _DeclineSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const _DeclineSheet({required this.user});

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
  late final List<_DriverDoc> _docs;
  late final Set<String> _declined;
  final _reasonController = TextEditingController();

  static const _quickReasons = [
    "Photo is blurry / unreadable",
    "Document expired",
    "Information doesn't match profile",
    "Looks edited or fake",
    "Glare covers important details",
    "Wrong document uploaded",
  ];

  @override
  void initState() {
    super.initState();
    _docs = _buildDocs(widget.user).where((d) => d.exists).toList();
    _declined = <String>{};
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (_declined.isEmpty && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFF87171),
          content: Text(
            "Select at least one declined document OR write a reason",
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _DeclineResult(
        _declined.toList(),
        _docs
            .where((d) => _declined.contains(d.key))
            .map((d) => d.label)
            .toList(),
        reason.isEmpty ? "Documents did not pass review" : reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                Icon(Icons.report_rounded, color: Color(0xFFF87171)),
                SizedBox(width: 10),
                Text(
                  "Decline Verification",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Select which documents are NOT acceptable. "
              "${widget.user['name'] ?? 'The driver'} will see exactly what to fix.",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            if (_docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF87171).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF87171).withOpacity(0.35),
                  ),
                ),
                child: const Text(
                  "No documents were uploaded by this driver.",
                  style: TextStyle(color: Color(0xFFF87171)),
                ),
              )
            else
              ..._docs.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeclinableDocTile(
                    doc: d,
                    declined: _declined.contains(d.key),
                    onChanged: (v) => setState(
                      () => v == true
                          ? _declined.add(d.key)
                          : _declined.remove(d.key),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),

            const Text(
              "REASON FOR DECLINE",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons
                  .map(
                    (r) => ActionChip(
                      backgroundColor: const Color(0xFF1A1F2E),
                      side: const BorderSide(color: Color(0x22FFFFFF)),
                      label: Text(
                        r,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      onPressed: () => setState(() {
                        _reasonController.text = r;
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Explain what's wrong…",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1F2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0x33FFFFFF)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF87171),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      "Send Rejection",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DeclinableDocTile extends StatelessWidget {
  final _DriverDoc doc;
  final bool declined;
  final ValueChanged<bool?> onChanged;

  const _DeclinableDocTile({
    required this.doc,
    required this.declined,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: declined
            ? const Color(0xFFF87171).withOpacity(0.10)
            : const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: declined
              ? const Color(0xFFF87171).withOpacity(0.55)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: CheckboxListTile(
        value: declined,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFFF87171),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        title: Text(
          doc.label,
          style: TextStyle(
            color: declined ? const Color(0xFFF87171) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
        subtitle: const Text(
          "Tap to mark as declined",
          style: TextStyle(color: Colors.grey, fontSize: 11.5),
        ),
      ),
    );
  }
}

class _VerifiedDriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final VoidCallback onRevoke;
  final VoidCallback? onOpenDetail;

  const _VerifiedDriverCard({
    required this.driver,
    required this.onRevoke,
    this.onOpenDetail,
  });

  String? _fmtDate(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null || d.year <= 1970) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final photo = driver['profile_photo_url'];
    final photoStr = photo?.toString() ?? '';
    final verifiedOn =
        _fmtDate(driver['updated_at']) ?? _fmtDate(driver['created_at']);

    return InkWell(
      onTap: onOpenDetail,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF34D399).withOpacity(0.35)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF1A1F2E),
              backgroundImage: photoStr.isNotEmpty
                  ? NetworkImage(photoStr)
                  : null,
              child: photoStr.isEmpty
                  ? Text(
                      (driver['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          driver['name'] ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Color(0xFF34D399),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${driver['phone'] ?? 'N/A'}  •  Plate: ${driver['plate_number'] ?? 'N/A'}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (verifiedOn != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "Verified on $verifiedOn",
                        style: TextStyle(
                          color: Colors.grey.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF87171),
                side: BorderSide(
                  color: const Color(0xFFF87171).withOpacity(0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onPressed: onRevoke,
              icon: const Icon(Icons.block_rounded, size: 15),
              label: const Text("Revoke", style: TextStyle(fontSize: 12.5)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
