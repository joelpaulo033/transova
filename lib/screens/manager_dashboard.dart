import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class ManagerDashboard extends ConsumerWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text('Operations Command Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Oversee daily logistics and assignments here.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
