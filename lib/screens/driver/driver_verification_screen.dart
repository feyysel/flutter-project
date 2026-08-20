import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      backgroundColor: const Color(0xFF050816),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050816),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text("Identity Verification",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text("Step\n2 of\n3",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11151F),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            const Text("Secure Your Account",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Paste image URLs for your verification documents.",
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
            const SizedBox(height: 35),
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
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user, color: Colors.deepPurple),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Your data is securely stored for verification purposes only.",
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 65,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  if (profileUrlController.text.isEmpty ||
                      idFrontUrlController.text.isEmpty ||
                      idBackUrlController.text.isEmpty ||
                      licenseUrlController.text.isEmpty ||
                      carPhotoUrlController.text.isEmpty ||
                      plateController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: Colors.red,
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
                          backgroundColor: Colors.green,
                          content: Text("Documents submitted successfully")),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
                    );
                  }

                  setState(() => isLoading = false);
                },
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Continue",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget textField({required TextEditingController controller, required String hint}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      onChanged: (value) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1A1F2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
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
        color: const Color(0xFF11151F),
        borderRadius: BorderRadius.circular(28),
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
                            fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, height: 1.4)),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.deepPurple.withOpacity(0.2),
                child: Icon(icon, color: Colors.deepPurple),
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
