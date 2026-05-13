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
      home: const ConfirmRideScreen(),
    );
  }
}

class ConfirmRideScreen extends StatelessWidget {
  const ConfirmRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ================= MAP SECTION (placeholder) =================
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE9EEF5),
            ),
            child: CustomPaint(
              painter: MapMockPainter(),
            ),
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back),
                  SizedBox(width: 10),
                  Text(
                    "Confirm Ride",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ),
          ),

          // ================= BOTTOM SHEET =================
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pickup
                  const RideLocationRow(
                    label: "PICKUP",
                    address: "725 Market Street, SF",
                    isPickup: true,
                  ),

                  const SizedBox(height: 15),

                  // Destination
                  const RideLocationRow(
                    label: "DESTINATION",
                    address: "Ferry Building, SF",
                    isPickup: false,
                  ),

                  const SizedBox(height: 20),

                  // Ride Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Economy",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "4 mins away • 3 seats",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          "\$14.50",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Payment
                  Row(
                    children: [
                      const Icon(Icons.credit_card, size: 18),
                      const SizedBox(width: 10),
                      const Text("Visa **** 8291"),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Change"),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Confirm Ride",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ================= LOCATION WIDGET =================
class RideLocationRow extends StatelessWidget {
  final String label;
  final String address;
  final bool isPickup;

  const RideLocationRow({
    super.key,
    required this.label,
    required this.address,
    required this.isPickup,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Icon(
              isPickup ? Icons.circle : Icons.location_on,
              size: 12,
              color: isPickup ? Colors.purple : Colors.black,
            ),
            Container(
              width: 2,
              height: 25,
              color: Colors.grey[300],
            ),
          ],
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              address,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
      ],
    );
  }
}

// ================= MAP MOCK PAINTER =================
class MapMockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    // grid lines (fake map)
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // route line
    final routePaint = Paint()
      ..color = Colors.purple
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.6)
      ..lineTo(size.width * 0.4, size.height * 0.7);

    canvas.drawPath(path, routePaint);

    // current location dot
    final dotPaint = Paint()..color = Colors.purple;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      8,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}