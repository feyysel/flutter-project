import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'passenger_activity_screen.dart';
import 'passenger_history_screen.dart';
import 'passenger_home_screen.dart';
import '../../services/ride_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_side_menu.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({super.key});

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final imageController = TextEditingController();
  final _supabase = Supabase.instance.client;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  static const List<SideMenuItem> _menuItems = [
    SideMenuItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: "Home"),
    SideMenuItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: "Activity"),
    SideMenuItem(icon: Icons.person_outline, activeIcon: Icons.person, label: "Profile"),
  ];

  Widget _menuDestination(int index) {
    switch (index) {
      case 0:
        return PassengerHomeScreen();
      case 1:
        return PassengerActivityScreen();
      default:
        return PassengerProfileScreen();
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void showEditProfileDialog(dynamic userData) {
    nameController.text = userData?["name"] ?? "";
    phoneController.text = userData?["phone"] ?? "";
    imageController.text = userData?["profile_image"] ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile",
              style:
                  TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: imageController,
                  decoration:
                      const InputDecoration(labelText: "Profile Image URL"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _supabase.from('profiles').update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'profile_image': imageController.text,
                }).eq('id', _currentUserId);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Text("Profile updated")),
                );
                setState(() {});
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  int _memberSinceYear() {
    final createdAtStr = _supabase.auth.currentUser?.createdAt;
    if (createdAtStr == null) return DateTime.now().year;
    final date =
        DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now();
    return date.year;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _supabase
          .from('profiles')
          .select()
          .eq('id', _currentUserId)
          .maybeSingle(),
      builder: (context, snapshot) {
        Map<String, dynamic>? user = snapshot.data;
        final name = ((user?["name"] as String?)?.trim().isNotEmpty ?? false)
            ? user!["name"]
            : "Guest";
        final phone = user?["phone"]?.toString() ?? '';
        final image = user?["profile_image"] as String?;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Profile",
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4)),
            leading: Builder(
              builder: (menuContext) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(menuContext).openDrawer(),
              ),
            ),
          ),
          drawer: PremiumSideMenu(
            items: _menuItems,
            currentIndex: 2,
            roleLabel: 'Passenger',
            onLogout: _signOut,
            onItemTap: (index) => PremiumSideMenu.navigateAfterClose(
              context,
              _menuDestination(index),
              isCurrent: index == 2,
            ),
          ),
          body: PremiumBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: AppColors.surfaceHigh,
                      backgroundImage: image != null && image.isNotEmpty
                          ? NetworkImage(image)
                          : null,
                      child: image == null || image.isEmpty
                          ? const Icon(Icons.person_rounded,
                              size: 44, color: AppColors.textSecondary)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary)),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(phone,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.30)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            size: 14, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text("PASSENGER",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: AppColors.gold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: RideService.getRideHistory(
                              _currentUserId,
                              field: 'passenger_id'),
                          builder: (context, tripSnapshot) {
                            final trips = tripSnapshot.data?.length ?? 0;
                            return _StatCard(
                              icon: Icons.route_rounded,
                              label: "Total Trips",
                              value: "$trips",
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.calendar_today_rounded,
                          label: "Member Since",
                          value: "${_memberSinceYear()}",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(left: 4, bottom: 14),
                      child: const MicroLabel("Account"),
                    ),
                  ),
                  _MenuTile(
                    icon: Icons.history_rounded,
                    label: "Trip History",
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PassengerHistoryScreen()));
                    },
                  ),
                  _MenuTile(
                    icon: Icons.edit_rounded,
                    label: "Edit Profile",
                    onTap: () => showEditProfileDialog(user),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _signOut,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              size: 19, color: AppColors.danger),
                          const SizedBox(width: 9),
                          const Text("Log Out",
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger)),
                        ],
                      ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
