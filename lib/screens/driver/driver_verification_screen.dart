import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() => _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen> {
  final _supabase = Supabase.instance.client;

  final profileUrlController = TextEditingController();
  final idFrontUrlController = TextEditingController();
  final idBackUrlController = TextEditingController();
  final licenseUrlController = TextEditingController();
  final carPhotoUrlController = TextEditingController();
  final plateController = TextEditingController();

  bool isLoading = false;

  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text("Identity Verification",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4)),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Text("STEP 2 OF 3",
                style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                    letterSpacing: 1.2)),
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
              const Text("Secure Your Account",
                  style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              const Text("Paste image URLs for your verification documents.",
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15, height: 1.5)),
              const SizedBox(height: 30),
            verificationCard(
              title: "Profile Photo",
              subtitle: "Paste profile image URL.",
              icon: Icons.person_outline,
              child: Column(
                children: [
                  textField(controller: profileUrlController, hint: "https://example.com/profile.jpg"),
                  const SizedBox(height: 15),
                  if (profileUrlController.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        profileUrlController.text,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                                child: Text("Invalid Image URL", style: TextStyle(color: Colors.white))),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            verificationCard(
              title: "Vehicle Information",
              subtitle: "Enter plate number and car image URL.",
              icon: Icons.directions_car,
              child: Column(
                children: [
                  textField(controller: plateController, hint: "Plate Number"),
                  const SizedBox(height: 20),
                  textField(controller: carPhotoUrlController, hint: "https://example.com/car.jpg"),
                  const SizedBox(height: 15),
                  if (carPhotoUrlController.text.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        carPhotoUrlController.text,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F2E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                                child: Text("Invalid Image URL", style: TextStyle(color: Colors.white))),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            verificationCard(
              title: "Identity Card",
              subtitle: "Front and back image URLs.",
              icon: Icons.badge_outlined,
              child: Column(
                children: [
                  textField(controller: idFrontUrlController, hint: "Front ID Image URL"),
                  const SizedBox(height: 15),
                  textField(controller: idBackUrlController, hint: "Back ID Image URL"),
                ],
              ),
            ),
            const SizedBox(height: 25),
            verificationCard(
              title: "Driver's License",
              subtitle: "Paste license image URL.",
              icon: Icons.workspace_premium_outlined,
              child: textField(controller: licenseUrlController, hint: "https://example.com/license.jpg"),
            ),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
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
                          color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PremiumButton(
              label: "Submit for Review",
              icon: const Icon(Icons.verified_user_rounded,
                  color: Colors.white, size: 20),
              loading: isLoading,
              onPressed: isLoading ? null : () => _submitVerification(context),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _submitVerification(BuildContext context) async {
    if (profileUrlController.text.isEmpty ||
        idFrontUrlController.text.isEmpty ||
        idBackUrlController.text.isEmpty ||
        licenseUrlController.text.isEmpty ||
        carPhotoUrlController.text.isEmpty ||
        plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text("Complete all verification fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _supabase.from('profiles').update({
        'profile_photo_url': profileUrlController.text,
        'id_front_url': idFrontUrlController.text,
        'id_back_url': idBackUrlController.text,
        'license_url': licenseUrlController.text,
        'car_photo_url': carPhotoUrlController.text,
        'plate_number': plateController.text,
        'verification_status': 'under_review',
        'is_verified': false,
      }).eq('id', _currentUserId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            backgroundColor: AppColors.success,
            content: Text("Documents submitted successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors.danger, content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  Widget textField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary),
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }

  Widget verificationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(28),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
              GradientIconTile(icon: icon, size: 46, radius: 15, iconSize: 22),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
