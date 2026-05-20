import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';

class DriverDashboardScreen extends StatelessWidget {
  final AuthService authService;

  const DriverDashboardScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: TransovaTheme.background,
      appBar: AppBar(
        backgroundColor: TransovaTheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver Portal', style: TextStyle(color: TransovaTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Welcome, ${user?.displayName ?? 'Driver'}', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: TransovaTheme.error),
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TransovaTheme.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TransovaTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Current Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Switch(
                    value: true, // Connect this to Firestore driver status
                    activeColor: TransovaTheme.primary,
                    onChanged: (val) {
                      // Update status in Firestore
                    },
                  ),
                  const Text('In Transit', style: TextStyle(color: TransovaTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Current Assignment Card
            const Text('Current Assignment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: TransovaTheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: TransovaTheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Booking #BKG-1042', style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: TransovaTheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                          child: const Text('ETA: 45 mins', style: TextStyle(color: TransovaTheme.onSecondaryContainer, fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.location_on, color: TransovaTheme.primary),
                      title: Text('Pickup: Kariakoo Terminal'),
                      subtitle: Text('10:00 AM'),
                    ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.flag, color: TransovaTheme.secondary),
                      title: Text('Dropoff: Mbezi Logistics Hub'),
                      subtitle: Text('11:30 AM'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () {},
                        child: const Text('Mark as Arrived', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Health Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {},
                    icon: const Icon(Icons.ev_station, color: TransovaTheme.secondary),
                    label: const Text('Log Fuel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: TransovaTheme.error),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.build, color: TransovaTheme.error),
                    label: const Text('Report Issue', style: TextStyle(color: TransovaTheme.error)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}