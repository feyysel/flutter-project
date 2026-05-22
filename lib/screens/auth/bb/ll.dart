import 'package:flutter/material.dart';

void main() {
  runApp(const LuxeRideApp());
}

class LuxeRideApp extends StatelessWidget {
  const LuxeRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LuxeRide',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Roboto',
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LuxeRide"),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            onPressed: () {
              // Profile action
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to FluidMotion",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Passenger Option
            RoleCard(
              icon: Icons.location_pin,
              iconColor: Colors.deepPurple,
              title: "Passenger",
              description: "Request a premium ride instantly",
              buttonText: "Continue as Passenger",
              buttonColor: Colors.deepPurple,
              onPressed: () {
                // Navigate to passenger flow
              },
            ),
            const SizedBox(height: 20),

            // Driver Option
            RoleCard(
              icon: Icons.steering,
              iconColor: Colors.grey,
              title: "Driver",
              description: "Manage rides and earn premium",
              buttonText: "Continue as Driver",
              buttonColor: Colors.grey,
              onPressed: () {
                // Navigate to driver flow
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onPressed;

  const RoleCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onPressed,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
