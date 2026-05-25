import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'registration_screen.dart';
import 'dashboard_screen.dart';
import 'sanitation_ops_screen.dart';
import 'admin_analytics_screen.dart';
import 'driver_dashboard_screen.dart';
import 'manager_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final user = widget.authService.currentUser;
      if (user == null) return;

      // Role-based redirection
      switch (user.role) {
        case UserRole.admin:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminAnalyticsScreen(authService: widget.authService)));
          break;
        case UserRole.manager:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ManagerDashboardScreen(authService: widget.authService)));
          break;
        case UserRole.driver:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DriverDashboardScreen(authService: widget.authService)));
          break;
        default:
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(authService: widget.authService)));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
    }
  }

  void _showPasswordResetDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: resetEmailController,
          decoration: const InputDecoration(labelText: 'Enter your email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await widget.authService.resetPassword(resetEmailController.text.trim());
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('If the email exists, a reset link has been sent.')));
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TransovaTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TransovaTheme.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.local_shipping, size: 80, color: TransovaTheme.primary),
              const SizedBox(height: TransovaTheme.spaceLg),
              Text('Transova Logistics', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: TransovaTheme.spaceMd),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: TransovaTheme.spaceMd),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: TransovaTheme.spaceLg),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
              ),
              const SizedBox(height: TransovaTheme.spaceMd),
              TextButton(onPressed: _showPasswordResetDialog, child: const Text('Forgot Password?')),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RegistrationScreen(authService: widget.authService))),
                child: const Text('Don\'t have an account? Register'),
              ),
              TextButton(
                onPressed: () async {
                  await widget.authService.continueAsGuest();
                  if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(authService: widget.authService)));
                },
                child: const Text('Continue as Guest', style: TextStyle(color: TransovaTheme.outline)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}