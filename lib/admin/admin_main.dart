import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_login.dart';
import 'admin_dashboard.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DriveOn Admin',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF7C4DFF),
          secondary: const Color(0xFFF2C14E),
          surface: const Color(0xFF11151F),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF050816),
        cardTheme: CardThemeData(
          color: const Color(0xFF11151F),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF11151F),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: session == null ? const AdminLoginScreen() : const AdminDashboard(),
    );
  }
}
