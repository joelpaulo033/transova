import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import Firebase Core
import 'firebase_options.dart';                  // 2. Import generated options
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'themes/transova_theme.dart';

void main() async {
  // 3. Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 4. Initialize Firebase
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
  // Initializing AuthService here now that Firebase is ready
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
          if (!_authService.isAuthenticated) {
            return LoginScreen(authService: _authService);
          }
          return DashboardScreen(authService: _authService);
        },
      ),
    );
  }
}