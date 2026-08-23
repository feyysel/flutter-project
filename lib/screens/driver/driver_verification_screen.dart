import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  List<String> rejectedKeys = [];
  String rejectionReason = '';

  File? profileImage;
  File? idFrontImage;
  File? idBackImage;
  File? licenseImage;
  File? carPhotoImage;

  final plateController = TextEditingController();

  bool isLoading = false;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  static const Map<String, String> _docLabels = {
    'profile_photo': 'Profile Photo',
    'id_front': 'ID Card — Front',
    'id_back': 'ID Card — Back',
    'license': "Driver's License",
    'car_photo': 'Vehicle Photo',
  };

  @override
  void initState() {
    super.initState();
    _loadRejectionInfo();
  }

  Future<void> _loadRejectionInfo() async {
    if (_currentUserId.isEmpty) return;
    final row = await _supabase
        .from('profiles')
        .select('verification_status, rejection_reason, rejected_documents')
        .eq('id', _currentUserId)
        .maybeSingle();
    if (!mounted || row == null) return;

    final raw = row['rejected_documents'];
    setState(() {
      rejectionReason = (row['rejection_reason'] ?? '').toString();
      rejectedKeys = raw is List
          ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : [];
      if ((row['verification_status'] ?? '') != 'rejected') {
        rejectedKeys = [];
        rejectionReason = '';
      }
    });
  }

  Future<void> _pickImage(void Function(File?) setImage) async {
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
                style: TextStyle(color: AppColors.textPrimary),
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
                style: TextStyle(color: AppColors.textPrimary),
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

    setState(() => setImage(File(picked.path)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          "Identity Verification",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              "STEP 2 OF 3",
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                "Secure Your Account",
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Upload photos of your verification documents.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              if (rejectionReason.isNotEmpty || rejectedKeys.isNotEmpty) ...[
                const SizedBox(height: 22),
                _buildRejectionNotice(),
              ],
              const SizedBox(height: 30),
              verificationCard(
                title: "Profile Photo",
                subtitle: "Upload a clear profile picture.",
                icon: Icons.person_outline,
                docKey: 'profile_photo',
                child: _ImagePickerField(
                  label: "Profile Photo",
                  image: profileImage,
                  onPick: () => _pickImage((file) => profileImage = file),
                  rejected: rejectedKeys.contains('profile_photo'),
                ),
              ),
              const SizedBox(height: 25),
              verificationCard(
                title: "Vehicle Information",
                subtitle: "Enter plate number and upload car photo.",
                icon: Icons.directions_car,
                docKey: 'car_photo',
                child: Column(
                  children: [
                    TextField(
                      controller: plateController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: "Plate Number",
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ImagePickerField(
                      label: "Car Photo",
                      image: carPhotoImage,
                      onPick: () => _pickImage((file) => carPhotoImage = file),
                      rejected: rejectedKeys.contains('car_photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              verificationCard(
                title: "Identity Card",
                subtitle: "Upload front and back images.",
                icon: Icons.badge_outlined,
                docKey: 'id_front',
                child: Column(
                  children: [
                    _ImagePickerField(
                      label: "ID Front",
                      image: idFrontImage,
                      onPick: () => _pickImage((file) => idFrontImage = file),
                      rejected: rejectedKeys.contains('id_front'),
                    ),
                    const SizedBox(height: 15),
                    _ImagePickerField(
                      label: "ID Back",
                      image: idBackImage,
                      onPick: () => _pickImage((file) => idBackImage = file),
                      rejected: rejectedKeys.contains('id_back'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              verificationCard(
                title: "Driver's License",
                subtitle: "Upload your license photo.",
                icon: Icons.workspace_premium_outlined,
                docKey: 'license',
                child: _ImagePickerField(
                  label: "Driver's License",
                  image: licenseImage,
                  onPick: () => _pickImage((file) => licenseImage = file),
                ),
              ),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.30),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppColors.accent),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Your data is securely stored for verification purposes only.",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PremiumButton(
                label: "Submit for Review",
                icon: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                loading: isLoading,
                onPressed: isLoading ? null : () => _submitVerification(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitVerification() async {
    if (profileImage == null ||
        idFrontImage == null ||
        idBackImage == null ||
        licenseImage == null ||
        carPhotoImage == null ||
        plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text("Complete all verification fields"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final profileUrl = await StorageService.uploadDriverDocument(
        profileImage!,
        _currentUserId,
        fileName: 'profile',
      );
      final idFrontUrl = await StorageService.uploadDriverDocument(
        idFrontImage!,
        _currentUserId,
        fileName: 'id_front',
      );
      final idBackUrl = await StorageService.uploadDriverDocument(
        idBackImage!,
        _currentUserId,
        fileName: 'id_back',
      );
      final licenseUrl = await StorageService.uploadDriverDocument(
        licenseImage!,
        _currentUserId,
        fileName: 'license',
      );
      final carUrl = await StorageService.uploadDriverDocument(
        carPhotoImage!,
        _currentUserId,
        fileName: 'car_photo',
      );

      await _supabase
          .from('profiles')
          .update({
            'profile_photo_url': profileUrl,
            'id_front_url': idFrontUrl,
            'id_back_url': idBackUrl,
            'license_url': licenseUrl,
            'car_photo_url': carUrl,
            'plate_number': plateController.text,
            'verification_status': 'under_review',
            'is_verified': false,
          })
          .eq('id', _currentUserId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text("Documents submitted successfully"),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(e.toString()),
        ),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  Widget _buildRejectionNotice() {
    return Container(
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
                "Previous Submission Declined",
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (rejectedKeys.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rejectedKeys
                  .map(
                    (k) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _docLabels[k] ?? k,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            Text(
              "Re-upload the highlighted documents below.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
            ),
          ],
          if (rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"$rejectionReason"',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontStyle: FontStyle.italic,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget verificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    String? docKey,
  }) {
    final isDeclined = docKey != null && rejectedKeys.contains(docKey);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDeclined ? AppColors.danger : AppColors.border,
          width: isDeclined ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDeclined
                            ? AppColors.danger
                            : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDeclined)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    "DECLINED",
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                )
              else
                GradientIconTile(
                  icon: icon,
                  size: 46,
                  radius: 15,
                  iconSize: 22,
                ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  final String label;
  final File? image;
  final VoidCallback onPick;
  final bool rejected;

  const _ImagePickerField({
    required this.label,
    required this.image,
    required this.onPick,
    this.rejected = false,
  });

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              image!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onPick,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rejected ? AppColors.danger : AppColors.border,
            width: rejected ? 2 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              rejected ? Icons.restart_alt_rounded : Icons.add_a_photo_outlined,
              color: rejected ? AppColors.danger : AppColors.primary,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              rejected ? "Re-upload $label" : "Upload $label",
              style: TextStyle(
                color: rejected ? AppColors.danger : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rejected ? "This document was declined" : "Gallery or Camera",
              style: TextStyle(
                color: rejected
                    ? AppColors.danger.withValues(alpha: 0.8)
                    : AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
