import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/trip_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_ui.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.request});

  final Map<String, dynamic> request;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ImagePicker _picker = ImagePicker();
  final _txnController = TextEditingController();

  File? _receiptFile;
  bool _submitting = false;

  String get _bankName =>
      (widget.request['pay_bank_name'] ?? '').toString().trim();
  String get _holder =>
      (widget.request['pay_bank_holder'] ?? '').toString().trim();
  String get _account =>
      (widget.request['pay_account_number'] ?? '').toString().trim();

  Future<void> _pickReceipt(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() => _receiptFile = File(picked.path));
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title:
                  const Text("Choose from Gallery", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickReceipt(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text("Take a Photo", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickReceipt(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _copy(String value, String label) {
    if (value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceHigh,
        content: Text("$label copied"),
      ),
    );
  }

  Widget _bankRow(IconData icon, String label, String value, {bool copyable = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MicroLabel(label, color: AppColors.textMuted),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? "—" : value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (copyable && value.isNotEmpty)
            GestureDetector(
              onTap: () => _copy(value, label),
              child: const Icon(Icons.copy_rounded,
                  size: 17, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text("Attach your payment receipt screenshot first"),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await TripService.submitPayment(
        request: widget.request,
        receiptFile: _receiptFile!,
        transactionNumber:
            _txnController.text.trim().isEmpty ? null : _txnController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text("Receipt sent to driver for verification"),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text("Failed to send receipt: $e"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _txnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          const MicroLabel('Complete payment', color: AppColors.accent),
                          const SizedBox(height: 5),
                          const Text(
                            "Pay & send receipt",
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
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MicroLabel('Amount to transfer', color: Colors.white70),
                      const SizedBox(height: 6),
                      Text(
                        "${widget.request['price']} ETB",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "for ${widget.request['from']} → ${widget.request['to']}",
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Transfer externally using any of the details below, "
                  "then attach your receipt screenshot so the driver can verify.",
                  style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _bankRow(Icons.account_balance_rounded, 'Bank', _bankName),
                      const SizedBox(height: 10),
                      _bankRow(Icons.person_outline_rounded, 'Account holder', _holder),
                      const SizedBox(height: 10),
                      _bankRow(Icons.numbers_rounded, 'Account number', _account),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _showPickSheet,
                  child: Container(
                    width: double.infinity,
                    height: 190,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _receiptFile == null
                            ? AppColors.border
                            : AppColors.success.withValues(alpha: 0.55),
                        width: _receiptFile == null ? 1 : 1.6,
                      ),
                    ),
                    child: _receiptFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.upload_file_rounded,
                                    color: AppColors.accent, size: 26),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "Attach receipt screenshot",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Required — tap to choose or take a photo",
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_receiptFile!, fit: BoxFit.cover),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: CircleAvatar(
                                    radius: 17,
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.close_rounded,
                                          size: 17, color: Colors.white),
                                      onPressed: () =>
                                          setState(() => _receiptFile = null),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _txnController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: "Transaction number (optional)",
                  ),
                ),
                const SizedBox(height: 24),

                PremiumButton(
                  label: _submitting ? "Sending…" : "Send Receipt to Driver",
                  loading: _submitting,
                  onPressed: _submitting ? () {} : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
