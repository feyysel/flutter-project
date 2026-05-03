import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      home: const AccountStatusScreen(),
    );
  }
}

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.arrow_back),
        title: const Text("Account Status"),
        actions: const [
          Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.notifications_none))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Status Header

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.purple.shade50),
              child: const Icon(Icons.pending_actions,
                  size: 50, color: Colors.purple),
            ),

            const SizedBox(height: 5),

            const Text("Your documents are under review",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  _buildProgressItem("Identity Verification",
                      "Government ID & Photo", "PENDING", Colors.grey.shade200),
                  const Divider(),
                  _buildProgressItem("Driver's License", "Class D Professional",
                      "UNDER REVIEW", Colors.purple.shade100,
                      isUnderReview: true),
                  const Divider(),
                  _buildProgressItem("Vehicle Registration",
                      "2024 Toyota Camry", "PENDING", Colors.grey.shade200),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Buttons

            ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white),
                child: const Text("Contact Support")),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
                side: BorderSide.none,
              ),
              child: const Text("Back to Login"),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.verified_user), label: 'Status'),
          BottomNavigationBarItem(
              icon: Icon(Icons.help_outline), label: 'Support'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
          String title, String subtitle, String status, Color statusColor,
          {bool isUnderReview = false}) =>
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.folder_shared, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: statusColor, borderRadius: BorderRadius.circular(20)),
          child: Text(status,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isUnderReview ? Colors.purple : Colors.black54)),
        ),
      );

  Widget _buildInfoCard(IconData icon, String title, String subtitle) => Card(
        child: ListTile(
          leading: Icon(icon, color: Colors.purple),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
        ),
      );
}
