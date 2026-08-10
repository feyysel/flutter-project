import 'package:flutter/material.dart';
import 'screens/common/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/common/role_selection.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DriveOn — Intercity Ride Sharing',
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: FirebaseAuth.instance.currentUser == null
    ? SplashScreen()
    : RoleSelectionScreen(),
    );
  }
}
