import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';

class ManagerDashboardScreen extends StatelessWidget {
  final AuthService authService;

  const ManagerDashboardScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TransovaTheme.background,
      appBar: AppBar(
        backgroundColor: TransovaTheme.surface,
        title: const Text('Operations Manager', style: TextStyle(color: TransovaTheme.primary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: TransovaTheme.onSurfaceVariant), onPressed: () {}),
          IconButton(icon: const Icon(Icons.logout, color: TransovaTheme.error), onPressed: () => authService.logout()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('Active Trips', '12', Icons.local_shipping, TransovaTheme.primary)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Pending Approvals', '4', Icons.assignment_late, TransovaTheme.secondary)),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Approvals Section
            const Text('Action Required: Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2, // Example count
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: TransovaTheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: TransovaTheme.outlineVariant)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text('Customer Request #${1050 + index}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Dar es Salaam → Dodoma\nRequires: 5 Ton Truck'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: TransovaTheme.error),
                          onPressed: () {},
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.primary),
                          onPressed: () {},
                          child: const Text('Approve'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Fleet Status Overview
            const Text('Fleet Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TransovaTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TransovaTheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _buildFleetRow('TRK-8829', 'In Transit', TransovaTheme.primary),
                  const Divider(),
                  _buildFleetRow('TRK-1044', 'Available', Colors.green),
                  const Divider(),
                  _buildFleetRow('TRK-9902', 'Maintenance', TransovaTheme.error),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildFleetRow(String truckId, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, color: TransovaTheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(truckId, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}