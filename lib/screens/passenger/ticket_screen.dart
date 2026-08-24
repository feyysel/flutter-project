import 'package:flutter/material.dart';
import 'ticket_screen_barcode.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key, required this.request});

  final Map<String, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final ticketCode = (request['ticket_code'] ?? '').toString();
    final verified = request['payment_verified_at'] != null;

    return Material(
      type: MaterialType.transparency,
      child: SheetPage(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const MicroLabel('Boarding pass', color: AppColors.gold),
                          const SizedBox(height: 5),
                          const Text(
                            "Your ticket",
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlassCircleButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppGradients.primary,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(27)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.confirmation_number_rounded,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "DriveOn E-Ticket",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    verified ? "PAID • SEAT RESERVED" : "TICKET",
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const MicroLabel('From'),
                                      const SizedBox(height: 5),
                                      Text(
                                        "${request['from'] ?? ''}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Icon(Icons.arrow_forward_rounded,
                                      size: 20, color: AppColors.accent),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const MicroLabel('To'),
                                      const SizedBox(height: 5),
                                      Text(
                                        "${request['to'] ?? ''}",
                                        textAlign: TextAlign.right,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            _row("Passenger", "${request['passenger_name'] ?? ''}"),
                            _row("Driver", "${request['driver_name'] ?? ''}"),
                            _row("Vehicle", "${request['driver_plate'] ?? ''}"),
                            _row("Departure", "${request['time'] ?? ''}"),
                            _row("Fare paid", "${request['price'] ?? '0'} ETB"),

                            const SizedBox(height: 14),

                            Row(
                              children: [
                                const Icon(Icons.verified_user_rounded,
                                    size: 15, color: AppColors.success),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    verified
                                        ? "Payment verified by driver"
                                        : "Payment under review",
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: verified
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      CustomPaint(
                        painter: DashedDividerPainter(),
                        child: const SizedBox(width: double.infinity, height: 1),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const MicroLabel('Ticket code', color: AppColors.textMuted),
                            const SizedBox(height: 6),
                            Text(
                              ticketCode.isEmpty ? "—" : ticketCode,
                              style: const TextStyle(
                                fontSize: 21,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (ticketCode.isNotEmpty)
                              SizedBox(
                                height: 62,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: BarcodePainter(code: ticketCode),
                                ),
                              ),
                            const SizedBox(height: 14),
                            Text(
                              "Keep this ticket as evidence of payment and travel.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
