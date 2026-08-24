import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/live_query.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  Stream<List<Map<String, dynamic>>> get _stream {
    return LiveQuery.watch(
      table: 'notifications',
      eq1Column: _currentUserId.isEmpty ? null : 'user_id',
      eq1Value: _currentUserId.isEmpty ? null : _currentUserId,
      interval: const Duration(seconds: 6),
    ).map((rows) {
      rows.sort((a, b) => (a['created_at'] ?? '')
          .toString()
          .compareTo((b['created_at'] ?? '').toString()));
      return rows;
    });
  }

  Future<void> _markRead(List<Map<String, dynamic>> unread) async {
    if (unread.isEmpty) return;
    try {
      await Future.wait(
        unread.map(
          (n) => _supabase
              .from('notifications')
              .update({'read': true})
              .eq('id', n['id']),
        ),
      );
    } catch (_) {}
  }

  void _onItemTap(Map<String, dynamic> n) {
    if (n['read'] == false) {
      _supabase.from('notifications').update({'read': true}).eq('id', n['id']);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              n['body'] ?? '',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '');
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${d.day}/${d.month}/${d.year}";
  }

  (IconData, Color) _style(String title) {
    final t = title.toLowerCase();
    if (t.contains('accept'))
      return (Icons.check_circle_rounded, AppColors.success);
    if (t.contains('declin') || t.contains('reject')) {
      return (Icons.cancel_rounded, AppColors.danger);
    }
    if (t.contains('verif')) {
      return (Icons.verified_rounded, AppColors.success);
    }
    if (t.contains('complet'))
      return (Icons.task_alt_rounded, AppColors.primaryVivid);
    if (t.contains('request'))
      return (Icons.notifications_active_rounded, AppColors.gold);
    return (Icons.notifications_rounded, AppColors.accent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              final unread =
                  snapshot.data?.where((n) => n['read'] == false).toList() ??
                  [];
              if (unread.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => _markRead(unread),
                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 17,
                    color: AppColors.accent,
                  ),
                  label: const Text(
                    "Mark all read",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: PremiumBackground(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var items = snapshot.data ?? <Map<String, dynamic>>[];
            items = List<Map<String, dynamic>>.from(items)
              ..sort(
                (a, b) => ((b['created_at'] ?? '') as String).compareTo(
                  (a['created_at'] ?? '') as String,
                ),
              );

            if (items.isEmpty) {
              return const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: "No notifications yet",
                message: "Ride updates and account news will appear here.",
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async {},
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _NotificationTile(
                  notification: items[index],
                  styleFor: _style,
                  timeAgo: _timeAgo,
                  onTap: () => _onItemTap(items[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final (IconData, Color) Function(String) styleFor;
  final String Function(dynamic) timeAgo;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.styleFor,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = notification['read'] == false;
    final (icon, color) = styleFor(notification['title'] ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.09)
              : AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.30)),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 7),
                      Text(
                        timeAgo(notification['created_at']),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if ((notification['body'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      notification['body'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isUnread
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
