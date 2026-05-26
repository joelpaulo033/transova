import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'customer_dashboard.dart';
import 'driver_dashboard.dart';
import 'manager_dashboard.dart';
import 'admin_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userValue = ref.watch(userProvider);

    return userValue.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Unauthorized')));

        switch (user.role) {
          case UserRole.admin:
            return const AdminDashboard();
          case UserRole.customer:
            return const CustomerDashboard();
          case UserRole.driver:
            return const DriverDashboard();
          case UserRole.manager:
            return const ManagerDashboard();
          default:
            return const CustomerDashboard();
        }
      },
    );
  }
}
