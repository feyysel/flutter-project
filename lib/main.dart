import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/common/splash_screen.dart';
import 'screens/common/role_selection.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey, // TODO: migrate to publishableKey when upgrading Supabase package
  );

  runApp(const MyApp());
  unawaited(NotificationService.initialize());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DriveOn — Intercity Ride Sharing',
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: session == null ? SplashScreen() : RoleSelectionScreen(),
    );
  }
}
