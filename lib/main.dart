import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verification',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const VerificationScreen(),
    );
  }
}

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(4, (_) => FocusNode());

  int _resendCooldown = 30;
  bool _isResendEnabled = false;
  bool _isError = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ✅ FIXED TIMER
  void _startResendTimer() {
    _timer?.cancel();

    setState(() {
      _resendCooldown = 30;
      _isResendEnabled = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  String getOtp() => _controllers.map((c) => c.text).join();

  // ✅ FIXED VERIFY
  void verifyCode() {
    String otp = getOtp();

    if (otp.length != 4) {
      setState(() => _isError = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Enter complete 4-digit code"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isError = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Code Verified: $otp"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ✅ FIXED PASTE
  Future<void> _pasteOTP() async {
    final data = await Clipboard.getData('text/plain');

    if (data?.text == null) return;

    String pasted = data!.text!.trim();

    if (pasted.length == 4 && int.tryParse(pasted) != null) {
      for (int i = 0; i < 4; i++) {
        _controllers[i].text = pasted[i];
      }

      _focusNodes.last.requestFocus();

      setState(() => _isError = false);

      verifyCode();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void resendCode() {
    if (!_isResendEnabled) return;

    for (var c in _controllers) {
      c.clear();
    }

    _focusNodes.first.requestFocus();

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📨 Code resent")),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 60,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isError
              ? Colors.red
              : (_controllers[index].text.isNotEmpty
                  ? Colors.deepPurple
                  : Colors.grey),
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
        ),
        onChanged: (value) {
          setState(() {});

          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          if (getOtp().length == 4) {
            verifyCode();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verification")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Enter OTP Code",
              style: TextStyle(fontSize: 22),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, _buildOtpBox),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: verifyCode,
              child: const Text("Verify"),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: resendCode,
              child: Text(
                _isResendEnabled
                    ? "Resend Code"
                    : "Wait $_resendCooldown s",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _pasteOTP,
              child: const Text("Paste OTP"),
            ),
          ],
        ),
      ),
    );
  }
}