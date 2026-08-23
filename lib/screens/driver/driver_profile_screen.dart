import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'driver_ride_post_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_home_screen.dart';
import 'driver_history_screen.dart';
import 'driver_verification_screen.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_side_menu.dart';

class DriverProfileScreen extends StatefulWidget {
  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _supabase = Supabase.instance.client;

  static const Map<String, String> _docLabels = {
    'profile_photo': 'Profile Photo',
    'id_front': 'ID Card — Front',
    'id_back': 'ID Card — Back',
    'license': "Driver's License",
    'car_photo': 'Vehicle Photo',
  };

  List<String> get _rejectedDocKeys {
    final raw = driverData?['rejected_documents'];
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  String get _rejectionReason =>
      (driverData?['rejection_reason'] ?? '').toString();

  static const List<SideMenuItem> _menuItems = [
    SideMenuItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: "Map"),
    SideMenuItem(
      icon: Icons.add_circle_outline,
      activeIcon: Icons.add_circle,
      label: "Ride Post",
    ),
    SideMenuItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: "Earnings",
    ),
    SideMenuItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: "Profile",
    ),
  ];

  Widget _menuDestination(int index) {
    switch (index) {
      case 0:
        return DriverHomeScreen();
      case 1:
        return DriverRidePostScreen();
      case 2:
        return DriverEarningsScreen();
      default:
        return DriverProfileScreen();
    }
  }

  Map<String, dynamic>? driverData;
  int totalTrips = 0;
  double acceptanceRate = 0;
  String yearsDriving = "0";

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    loadDriverData();
  }

  Future<void> loadDriverData() async {
    if (_currentUserId.isEmpty) return;

    final doc = await _supabase
        .from('profiles')
        .select()
        .eq('id', _currentUserId)
        .maybeSingle();

    final completedTrips = await _supabase
        .from('ride_history')
        .select()
        .eq('driver_id', _currentUserId);

    final acceptedTrips = await _supabase
        .from('ride_requests')
        .select()
        .eq('driver_id', _currentUserId)
        .eq('status', 'accepted');

    final declinedTrips = await _supabase
        .from('ride_requests')
        .select()
        .eq('driver_id', _currentUserId)
        .eq('status', 'declined');

    int accepted = acceptedTrips.length;
    int declined = declinedTrips.length;

    double rate = 0;
    if ((accepted + declined) > 0) {
      rate = (accepted / (accepted + declined)) * 100;
    }

    final createdAtStr = _supabase.auth.currentUser?.createdAt;
    DateTime createdDate = DateTime.now();
    if (createdAtStr != null) {
      createdDate =
          DateTime.tryParse(createdAtStr.toString()) ?? DateTime.now();
    }
    int years = DateTime.now().year - createdDate.year;

    setState(() {
      driverData = doc;
      totalTrips = completedTrips.length;
      acceptanceRate = rate;
      yearsDriving = years <= 0 ? "1" : years.toString();
    });
  }

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final _picker = ImagePicker();
  File? newImageFile;
  String existingImageUrl = "";

  Future<void> pickProfileImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                "Choose from Gallery",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary,
              ),
              title: const Text(
                "Take a Photo",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 70);
    if (picked == null) return;

    setState(() => newImageFile = File(picked.path));
  }

  void showEditProfileDialog(dynamic userData) {
    nameController.text = userData?["name"] ?? "";
    phoneController.text = userData?["phone"] ?? "";
    existingImageUrl = userData?["profile_image"] ?? "";
    newImageFile = null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Edit Profile"),
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
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        await pickProfileImage();
                        setDialogState(() {});
                      },
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: newImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  newImageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: existingImageUrl.isNotEmpty
                                        ? NetworkImage(existingImageUrl)
                                        : null,
                                    child: existingImageUrl.isEmpty
                                        ? const Icon(Icons.person, size: 28)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Tap to change profile photo",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String imageUrl = existingImageUrl;

                    if (newImageFile != null && _currentUserId.isNotEmpty) {
                      try {
                        imageUrl = await StorageService.uploadProfileImage(
                          newImageFile!,
                          _currentUserId,
                        );
                      } catch (e) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(e.toString()),
                            ),
                          );
                        }
                        return;
                      }
                    }

                    await _supabase
                        .from('profiles')
                        .update({
                          'name': nameController.text,
                          'phone': phoneController.text,
                          'profile_image': imageUrl,
                        })
                        .eq('id', _currentUserId);

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.green,
                          content: Text("Profile updated"),
                        ),
                      );
                      loadDriverData();
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (driverData == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: PremiumSideMenu(
        items: _menuItems,
        currentIndex: 3,
        roleLabel: 'Driver',
        onLogout: logout,
        onItemTap: (index) => PremiumSideMenu.navigateAfterClose(
          context,
          _menuDestination(index),
          isCurrent: index == 3,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Builder(
                    builder: (menuContext) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(menuContext).openDrawer(),
                    ),
                  ),
                  const Text(
                    "Driver Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () => showEditProfileDialog(driverData),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                driverData != null &&
                                    driverData!["profile_image"] != null &&
                                    driverData!["profile_image"] != ""
                                ? NetworkImage(driverData!["profile_image"])
                                : null,
                            child:
                                driverData == null ||
                                    driverData!["profile_image"] == null ||
                                    driverData!["profile_image"] == ""
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => showEditProfileDialog(driverData),
                              child: const SizedBox(width: 88, height: 88),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      driverData!["name"] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, color: AppColors.primary, size: 18),
                        SizedBox(width: 5),
                        Text(
                          "4.95",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "• Professional Driver",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () {
                        if (driverData!["verification_status"] == "verified")
                          return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverVerificationScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color:
                              driverData!["verification_status"] == "verified"
                              ? AppColors.success.withValues(alpha: 0.14)
                              : driverData!["verification_status"] ==
                                    "under_review"
                              ? AppColors.warning.withValues(alpha: 0.14)
                              : driverData!["verification_status"] == "rejected"
                              ? AppColors.danger.withValues(alpha: 0.14)
                              : AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              driverData!["verification_status"] == "verified"
                                  ? "Verified Driver"
                                  : driverData!["verification_status"] ==
                                        "under_review"
                                  ? "Under Review"
                                  : driverData!["verification_status"] ==
                                        "rejected"
                                  ? "Documents Declined — Tap to Fix"
                                  : "Verify Account",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (driverData!["verification_status"] == "rejected") ...[
                      const SizedBox(height: 16),
                      _buildRejectionBanner(),
                    ],
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: statCard(
                              title: "TOTAL TRIPS",
                              value: totalTrips.toString(),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: statCard(
                              title: "YEARS DRIVING",
                              value: yearsDriving,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "ACCEPTANCE",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                letterSpacing: 2,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${acceptanceRate.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Account Settings",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    settingsTile(
                      icon: Icons.person,
                      title: "Personal Information",
                    ),
                    settingsTile(
                      icon: Icons.description,
                      title: "Documents & Insurance",
                    ),
                    settingsTile(
                      icon: Icons.history,
                      title: "Trip History",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DriverHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    settingsTile(icon: Icons.settings, title: "App Settings"),
                    settingsTile(icon: Icons.help, title: "Help & Support"),
                    const SizedBox(height: 35),
                    GestureDetector(
                      onTap: () async {
                        await AuthService.logout();
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        width: double.infinity,
                        height: 54,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              size: 19,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 9),
                            const Text(
                              "Log Out",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionBanner() {
    final rejectedKeys = _rejectedDocKeys;
    final reason = _rejectionReason;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gpp_bad_rounded, color: AppColors.danger, size: 20),
              SizedBox(width: 9),
              Text(
                "Verification Declined",
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rejectedKeys.isNotEmpty) ...[
            Text(
              "${rejectedKeys.length} document${rejectedKeys.length == 1 ? '' : 's'} need${rejectedKeys.length == 1 ? 's' : ''} to be re-uploaded:",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            ...rejectedKeys.map(
              (key) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _docLabels[key] ?? key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "REASON FROM ADMIN",
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverVerificationScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                "Re-upload Documents",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              letterSpacing: 2,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget settingsTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 17),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
