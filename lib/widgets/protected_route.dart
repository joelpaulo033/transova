import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProtectedRoute extends StatelessWidget {
  final Widget child;
  final AuthService authService;
  final UserRole requiredRole;

  const ProtectedRoute({
    super.key,
    required this.child,
    required this.authService,
    required this.requiredRole,
  });

  @override
  Widget build(BuildContext context) {
    if (authService.hasRole(requiredRole)) {
      return child;
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.red),
              const Text('Access Denied', style: TextStyle(fontSize: 24)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
  }
}