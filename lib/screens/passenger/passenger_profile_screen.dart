import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'passenger_activity_screen.dart';
import 'passenger_history_screen.dart';
import 'passenger_home_screen.dart';

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

  void showEditProfileDialog(dynamic userData) {
    nameController.text = userData?["name"] ?? "";
    phoneController.text = userData?["phone"] ?? "";
    imageController.text = userData?["profile_image"] ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF11151F),
          title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Name", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Phone", labelStyle: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: imageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Profile Image URL",
                      labelStyle: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
              onPressed: () async {
                await _supabase.from('profiles').update({
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'profile_image': imageController.text,
                }).eq('id', _currentUserId);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      backgroundColor: Colors.green, content: Text("Profile updated")),
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

  @override
  Widget build(BuildContext context) {
    int currentIndex = 2;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _supabase
          .from('profiles')
          .select()
          .eq('id', _currentUserId)
          .maybeSingle(),
      builder: (context, snapshot) {
        Map<String, dynamic>? user = snapshot.data;

        return Scaffold(
          backgroundColor: const Color(0xFF050816),
          appBar: AppBar(
            backgroundColor: const Color(0xFF11151F),
            elevation: 0,
            title: const Text("Profile", style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.deepPurple),
                onPressed: () => showEditProfileDialog(user),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user != null &&
                          user["profile_image"] != null &&
                          user["profile_image"] != ""
                      ? NetworkImage(user["profile_image"])
                      : null,
                  child: user == null ||
                          user["profile_image"] == null ||
                          user["profile_image"] == ""
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                  backgroundColor: const Color(0xFF11151F),
                ),
                const SizedBox(height: 15),
                Text(user?["name"] ?? "Guest",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("PASSENGER",
                      style: TextStyle(color: Colors.deepPurple)),
                ),
                const SizedBox(height: 25),
                const Row(
                  children: [
                    _StatCard("Total Trips", "12"),
                    SizedBox(width: 15),
                    _StatCard("Rewards", "1.2k"),
                  ],
                ),
                const SizedBox(height: 25),
                _MenuItem(Icons.history, "Trip History", onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PassengerHistoryScreen()));
                }),
                const _MenuItem(Icons.local_offer, "Promotions"),
                const _MenuItem(Icons.settings, "Settings"),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF11151F)),
                    onPressed: () async {
                      await _supabase.auth.signOut();
                      if (mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    child: const Text("Log Out",
                        style:
                            TextStyle(color: Color.fromARGB(255, 242, 4, 4))),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF11151F),
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() => currentIndex = index);
              if (index == 0) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => PassengerHomeScreen()));
              } else if (index == 1) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => PassengerActivityScreen()));
              } else if (index == 2) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => PassengerProfileScreen()));
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long), label: "Activity"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  const _MenuItem(this.icon, this.title, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF11151F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(width: 15),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
