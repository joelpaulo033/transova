import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';

class ManagerDashboardScreen extends StatelessWidget {
  final AuthService authService;

  const ManagerDashboardScreen({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fa), // Distinct light-gray background
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOperationalHighlights(),
                const SizedBox(height: 24),
                _buildActionRequiredSection(context),
                const SizedBox(height: 24),
                _buildOperationalFleetGrid(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: TransovaTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Ops Command Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(color: TransovaTheme.primary),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_active, color: Colors.white), onPressed: () {}),
        IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => authService.logout()),
      ],
    );
  }

  Widget _buildOperationalHighlights() {
    return Row(
      children: [
        _buildHighlightMetric('Active Operations', '12', Icons.trending_up, Colors.blue),
        const SizedBox(width: 16),
        _buildHighlightMetric('Urgent Reviews', '4', Icons.error_outline, TransovaTheme.error),
      ],
    );
  }

  Widget _buildHighlightMetric(String label, String value, IconData icon, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 32),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRequiredSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending Approvals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...List.generate(2, (index) => _buildApprovalTile(index)),
      ],
    );
  }

  Widget _buildApprovalTile(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: TransovaTheme.secondary, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Booking Ref: #TX-${1000 + index}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Text('Priority: High | Route: DSM to DOD', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          Row(children: [
            TextButton(onPressed: () {}, child: const Text('Reject', style: TextStyle(color: Colors.red))),
            ElevatedButton(onPressed: () {}, child: const Text('Authorize')),
          ])
        ],
      ),
    );
  }

  Widget _buildOperationalFleetGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fleet Health Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildFleetStatusItem('TRK-8829', 0.92, 'Operational'),
          _buildFleetStatusItem('TRK-9902', 0.45, 'Maintenance'),
        ],
      ),
    );
  }

  Widget _buildFleetStatusItem(String id, double health, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(id, style: const TextStyle(fontWeight: FontWeight.bold, )),
          Expanded(
            child: LinearProgressIndicator(value: health, color: health > 0.8 ? Colors.green : Colors.orange),
          ),
          const SizedBox(width: 16),
          Text(status, style: TextStyle(color: health > 0.8 ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}