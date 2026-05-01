// main.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const RideApp());
}

class RideApp extends StatelessWidget {
  const RideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'SF Pro', useMaterial3: true),
      home: const FindingRideScreen(),
    );
  }
}

// ========== MAIN SCREEN ==========
class FindingRideScreen extends StatefulWidget {
  const FindingRideScreen({super.key});

  @override
  State<FindingRideScreen> createState() => _FindingRideScreenState();
}

class _FindingRideScreenState extends State<FindingRideScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // ===== CORRECTED MAP BACKGROUND =====
          Positioned.fill(
            child: Stack(
              children: [
                // Base grey background
                Container(color: const Color(0xFFE8E8E8)),

                // Realistic city map
                CustomPaint(
                  painter: RealisticMapPainter(),
                  size: Size.infinite,
                ),

                // Animated radar circles
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: const RadarCircles(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFF8B5CF6)),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    const Text(
                      'Finding Your Ride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Sheet
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Searching for your ride...',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're finding the best driver near you",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: InfoCard(
                            icon: Icons.location_on,
                            iconColor: const Color(0xFF8B5CF6),
                            iconBgColor: const Color(0xFFF3E8FF),
                            label: 'PICK-UP',
                            value: '101 Market S',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InfoCard(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF0D9488),
                            iconBgColor: const Color(0xFFCCFBF1),
                            label: 'ESTIMATED',
                            value: '\$24.50',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5E7EB),
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Cancel Ride',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.local_taxi, 'RIDE', 0),
                  _buildNavItem(Icons.history, 'ACTIVITY', 1),
                  _buildNavItem(Icons.account_balance_wallet, 'WALLET', 2),
                  _buildNavItem(Icons.person_outline, 'PROFILE', 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF8B5CF6)
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== INFO CARD ==========
class InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;

  const InfoCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== RADAR CIRCLES ==========
class RadarCircles extends StatelessWidget {
  const RadarCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.25),
              width: 2.5,
            ),
          ),
        ),
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.35),
              width: 2.5,
            ),
          ),
        ),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.45),
              width: 2.5,
            ),
          ),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: Color(0xFF8B5CF6),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ========== CORRECTED REALISTIC MAP PAINTER ==========
class RealisticMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Road paint - thicker, white/light grey roads like in the screenshot
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Secondary road paint - thinner
    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Block/fill paint for buildings/areas
    final blockPaint = Paint()
      ..color = const Color(0xFFDCDCDC)
      ..style = PaintingStyle.fill;

    // Draw city blocks (building areas)
    _drawCityBlocks(canvas, size, blockPaint);

    // Draw main curved roads (the prominent arcs in the screenshot)
    _drawCurvedRoads(canvas, size, roadPaint);

    // Draw grid streets
    _drawGridStreets(canvas, size, secondaryRoadPaint);

    // Draw intersection dots
    _drawIntersections(canvas, size);
  }

  void _drawCityBlocks(Canvas canvas, Size size, Paint paint) {
    // Draw rectangular city blocks between roads
    final blocks = [
      Rect.fromLTWH(50, 80, 120, 90),
      Rect.fromLTWH(200, 60, 140, 110),
      Rect.fromLTWH(380, 90, 100, 80),
      Rect.fromLTWH(520, 70, 130, 100),
      Rect.fromLTWH(40, 220, 160, 100),
      Rect.fromLTWH(240, 200, 120, 120),
      Rect.fromLTWH(400, 230, 150, 90),
      Rect.fromLTWH(580, 210, 100, 110),
      Rect.fromLTWH(60, 380, 130, 100),
      Rect.fromLTWH(220, 360, 160, 130),
      Rect.fromLTWH(420, 390, 110, 100),
      Rect.fromLTWH(560, 370, 120, 120),
      Rect.fromLTWH(30, 530, 150, 110),
      Rect.fromLTWH(220, 540, 130, 90),
      Rect.fromLTWH(380, 520, 160, 120),
      Rect.fromLTWH(570, 540, 110, 100),
      Rect.fromLTWH(80, 700, 140, 100),
      Rect.fromLTWH(280, 680, 120, 130),
      Rect.fromLTWH(460, 710, 130, 90),
    ];

    for (var block in blocks) {
      // Slightly offset to create the "inset" look
      final insetBlock = block.deflate(4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(insetBlock, const Radius.circular(4)),
        paint,
      );
    }
  }

  void _drawCurvedRoads(Canvas canvas, Size size, Paint paint) {
    // Main horizontal curved road (the big arc visible in screenshot)
    final mainArcPath = Path();
    mainArcPath.moveTo(-50, size.height * 0.35);

    // Create a gentle upward arc across the screen
    mainArcPath.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.25,
      size.width * 0.5,
      size.height * 0.28,
    );
    mainArcPath.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.31,
      size.width + 50,
      size.height * 0.22,
    );
    canvas.drawPath(mainArcPath, paint..strokeWidth = 7);

    // Second curved road lower down
    final secondArcPath = Path();
    secondArcPath.moveTo(-50, size.height * 0.55);
    secondArcPath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.48,
      size.width * 0.5,
      size.height * 0.52,
    );
    secondArcPath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.56,
      size.width + 50,
      size.height * 0.50,
    );
    canvas.drawPath(secondArcPath, paint..strokeWidth = 6);

    // Diagonal curved road from top-right to bottom-left
    final diagonalPath = Path();
    diagonalPath.moveTo(size.width * 0.65, -50);
    diagonalPath.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.3,
      size.width * 0.45,
      size.height * 0.6,
    );
    diagonalPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.85,
      size.width * 0.25,
      size.height + 50,
    );
    canvas.drawPath(diagonalPath, paint..strokeWidth = 5);

    // Another diagonal from top-left
    final diagonal2Path = Path();
    diagonal2Path.moveTo(size.width * 0.2, -50);
    diagonal2Path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.25,
      size.width * 0.4,
      size.height * 0.5,
    );
    diagonal2Path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.75,
      size.width * 0.6,
      size.height + 50,
    );
    canvas.drawPath(diagonal2Path, paint..strokeWidth = 5);
  }

  void _drawGridStreets(Canvas canvas, Size size, Paint paint) {
    // Vertical streets
    final verticalX = [80.0, 180.0, 300.0, 420.0, 540.0, 620.0];
    for (var x in verticalX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal streets
    final horizontalY = [120.0, 250.0, 400.0, 550.0, 700.0, 850.0];
    for (var y in horizontalY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawIntersections(Canvas canvas, Size size) {
    final intersectionPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.fill;

    // Draw small circles at major intersections
    final intersections = [
      Offset(180, 250),
      Offset(300, 250),
      Offset(420, 400),
      Offset(300, 400),
      Offset(180, 550),
      Offset(540, 550),
      Offset(420, 700),
      Offset(300, 120),
    ];

    for (var point in intersections) {
      canvas.drawCircle(point, 8, intersectionPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
