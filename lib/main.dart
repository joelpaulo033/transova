import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/driver_dashboard_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sanitation_ops_screen.dart';
import 'screens/admin_analytics_screen.dart';
import 'services/auth_service.dart';
import 'themes/transova_theme.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Initialize the service once
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transova Logistics Platform',
      debugShowCheckedModeBanner: false,
      theme: TransovaTheme.lightTheme,
      home: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) {
          // 1. WHILE INITIALIZING: Show a spinner, NOT a white screen
          if (_authService.isInitializing) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 2. IF NOT LOGGED IN:
          if (!_authService.isAuthenticated) {
            return LoginScreen(authService: _authService);
          }

          // 3. IF LOGGED IN BUT ROLE NOT LOADED YET:
          final user = _authService.currentUser;
          if (user == null || user.role == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 4. REDIRECT:
          switch (user.role) {
            case UserRole.admin:
              return AdminAnalyticsScreen(authService: _authService); // Preserved from your original file
            case UserRole.manager:
              return SanitationOpsScreen(authService: _authService);
            case UserRole.driver:
              return DriverDashboardScreen(authService: _authService);
            default:
              return DashboardScreen(authService: _authService);
          }
        },
      ),
    );
  }
}