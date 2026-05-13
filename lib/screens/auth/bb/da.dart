import 'package:flutter/material.dart';

class RideSummaryPage extends StatelessWidget {
  const RideSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Ride Summary"),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🗺 Map placeholder
            Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFF355C66),
              child: const Center(
                child: Icon(Icons.map, color: Colors.white, size: 40),
              ),
            ),

            const SizedBox(height: 20),

            // 💳 Fare Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.deepPurple, size: 40),

                  const SizedBox(height: 10),

                  const Text(
                    "TOTAL FARE",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    "\$14.50",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildRow("Base Fare", "\$12.00"),
                  _buildRow("Service Fee", "\$4.50"),
                  _buildRow("Promotions", "-\$2.00", color: Colors.deepPurple),

                  const Divider(height: 25),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Paid via Apple Pay"),
                      Text("\$14.50"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 👨 Driver Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(
                      "https://i.pravatar.cc/150?img=3",
                    ),
                  ),
                  const SizedBox(width: 10),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "David",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text(" 4.9 (1,240 rides)"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () {},
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ⭐ Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return const Icon(Icons.star,
                    color: Colors.deepPurple, size: 32);
              }),
            ),

            const SizedBox(height: 10),

            // ✍ Feedback
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Write a feedback (optional)",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}           