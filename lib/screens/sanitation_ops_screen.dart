import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'admin_analytics_screen.dart';

class SanitationOpsScreen extends StatefulWidget {
  final AuthService? authService;
  const SanitationOpsScreen({super.key, this.authService});

  @override
  State<SanitationOpsScreen> createState() => _SanitationOpsScreenState();
}

class _SanitationOpsScreenState extends State<SanitationOpsScreen> {
  int _selectedMobileIndex = 3;

  void _onNavTap(int index) {
    if (index == _selectedMobileIndex) return;

    final user = widget.authService?.currentUser;
    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = DashboardScreen(authService: widget.authService!);
        break;
      case 1:
        nextScreen = RequestTransportScreen(authService: widget.authService);
        break;
      case 2:
        nextScreen = const FleetMaintenanceScreen();
        break;
      case 3:
        return; // Already here
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;
    final user = widget.authService?.currentUser;

    // SECURITY GUARD: Only authorized staff (not guests or customers) can access Ops
    final isAuthorized = user != null && user.role != UserRole.guest && user.role != UserRole.customer;

    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Restricted Area: Staff Only', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Home')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TransovaTheme.background,
      appBar: _buildAppBar(isDesktop),
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
      floatingActionButton: _buildFloatingActionButton(isDesktop),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) _buildNavigationSidebar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32.0 : 16.0,
                vertical: 24.0,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBentoStatsGrid(isDesktop),
                      const SizedBox(height: 24),
                      _buildDualSplitPanels(isDesktop),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: TransovaTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: isDesktop
          ? IconButton(
        icon: const Icon(Icons.arrow_back, color: TransovaTheme.onSurfaceVariant),
        onPressed: () => Navigator.pop(context),
      )
          : Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: TransovaTheme.onSurfaceVariant),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        isDesktop ? 'Sanitation Operations Management' : 'TRANSOVA',
        style: const TextStyle(
          color: TransovaTheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: TransovaTheme.onSurfaceVariant),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: TransovaTheme.onSurfaceVariant),
          onPressed: () {},
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = widget.authService?.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: TransovaTheme.primary),
            accountName: Text(user?.displayName ?? 'Staff Member'),
            accountEmail: Text(user?.email ?? 'Logged in'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: TransovaTheme.primary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(authService: widget.authService!)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RequestTransportScreen(authService: widget.authService)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: TransovaTheme.primary),
            title: const Text('Sanitation Ops', style: TextStyle(color: TransovaTheme.primary, fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context),
          ),
          if (user?.role == UserRole.admin)
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminAnalyticsScreen(authService: widget.authService!)));
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              widget.authService?.logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSidebar() {
    return Container(
      width: 320,
      color: TransovaTheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text(
              'TRANSOVA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: TransovaTheme.primary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: TransovaTheme.surfaceContainerHigh,
                  child: const Icon(Icons.person, color: TransovaTheme.onSurfaceVariant),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.authService?.currentUser?.displayName ?? 'Staff User',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onSurface),
                    ),
                    Text(
                      widget.authService?.currentUser?.role.name.toUpperCase() ?? 'STAFF',
                      style: const TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(Icons.grid_view, 'Dashboard', false, DashboardScreen(authService: widget.authService!)),
                _buildSidebarItem(Icons.map_outlined, 'Fleet Tracking', false),
                _buildSidebarItem(Icons.local_shipping_outlined, 'Bookings', false, RequestTransportScreen(authService: widget.authService)),
                _buildSidebarItem(Icons.delete_sweep, 'Sanitation Ops', true),
                if (widget.authService?.currentUser?.role == UserRole.admin)
                  _buildSidebarItem(Icons.analytics_outlined, 'Analytics', false, AdminAnalyticsScreen(authService: widget.authService!)),
                _buildSidebarItem(Icons.settings_outlined, 'Settings', false),
                const Spacer(),
                _buildSidebarItem(Icons.logout, 'Logout', false, null, () => widget.authService?.logout()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isActive, [Widget? screen, VoidCallback? onTap]) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? TransovaTheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(vertical: -1),
        leading: Icon(icon, color: isActive ? Colors.white : TransovaTheme.onSurfaceVariant),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : TransovaTheme.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (onTap != null) {
            onTap();
          } else if (screen != null) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
          }
        },
      ),
    );
  }

  Widget _buildBentoStatsGrid(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildSimpleMetricCard(
              title: 'ACTIVE TASKS',
              value: '42',
              footer: const Row(
                children: [
                  Icon(Icons.trending_up, size: 14, color: TransovaTheme.secondary),
                  SizedBox(width: 4),
                  Text(
                    '+12% from yesterday',
                    style: TextStyle(fontSize: 12, color: TransovaTheme.secondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSimpleMetricCard(
              title: 'FLEET UTILIZATION',
              value: '88%',
              footer: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  value: 0.88,
                  minHeight: 6,
                  backgroundColor: TransovaTheme.surfaceContainerHigh,
                  color: TransovaTheme.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Container(
              height: 125,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TransovaTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OPS EFFICIENCY INDEX',
                        style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      Text(
                        'Superior',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        'Daily objective: 95.0% completion rate (Current: 91.2%)',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                  Positioned(
                    right: -12,
                    bottom: -12,
                    child: Icon(Icons.analytics, size: 96, color: Colors.white10),
                  )
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSimpleMetricCard(
          title: 'ACTIVE TASKS',
          value: '42',
          footer: const Row(
            children: [
              Icon(Icons.trending_up, size: 14, color: TransovaTheme.secondary),
              SizedBox(width: 4),
              Text(
                '+12% from yesterday',
                style: TextStyle(fontSize: 12, color: TransovaTheme.secondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSimpleMetricCard(
          title: 'FLEET UTILIZATION',
          value: '88%',
          footer: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: const LinearProgressIndicator(
              value: 0.88,
              minHeight: 6,
              backgroundColor: TransovaTheme.surfaceContainerHigh,
              color: TransovaTheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TransovaTheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OPS EFFICIENCY INDEX',
                style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              SizedBox(height: 8),
              Text(
                'Superior',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Daily objective: 95.0% completion rate (Current: 91.2%)',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleMetricCard({required String title, required String value, required Widget footer}) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: TransovaTheme.outline, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TransovaTheme.primary),
          ),
          footer,
        ],
      ),
    );
  }

  Widget _buildDualSplitPanels(bool isDesktop) {
    if (isDesktop) {
      return const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _TaskQueuePanel()),
          SizedBox(width: 24),
          Expanded(flex: 5, child: _FleetAndSummaryPanel()),
        ],
      );
    }
    return const Column(
      children: [
        _TaskQueuePanel(),
        SizedBox(height: 24),
        _FleetAndSummaryPanel(),
      ],
    );
  }

  Widget _buildMobileBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedMobileIndex,
      backgroundColor: TransovaTheme.surface,
      indicatorColor: TransovaTheme.secondaryContainer,
      onDestinationSelected: _onNavTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Bookings'),
        NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Fleet'),
        NavigationDestination(
          icon: Icon(Icons.delete_sweep),
          selectedIcon: Icon(Icons.delete_sweep, color: TransovaTheme.onSecondaryContainer),
          label: 'Ops',
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(bool isDesktop) {
    final user = widget.authService?.currentUser;
    // Only Managers/Admins can create ops tasks
    if (user?.role == UserRole.admin || user?.role == UserRole.manager) {
      return FloatingActionButton(
        onPressed: () {},
        backgroundColor: TransovaTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      );
    }
    return const SizedBox.shrink();
  }
}

class _TaskQueuePanel extends StatelessWidget {
  const _TaskQueuePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Task Queue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TransovaTheme.primary),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          _buildTaskItem('Industrial Waste Collection', 'Unit TRK-402', 'High', TransovaTheme.error),
          const Divider(height: 32),
          _buildTaskItem('Commercial Septic Emptying', 'Unit TRK-882', 'Medium', TransovaTheme.tertiary),
          const Divider(height: 32),
          _buildTaskItem('Hazardous Material Disposal', 'Unit TRK-104', 'High', TransovaTheme.error),
          const Divider(height: 32),
          _buildTaskItem('Residential Route Alpha', 'Unit VAN-012', 'Routine', TransovaTheme.secondary),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String unit, String priority, Color priorityColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.assignment, color: priorityColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(unit, style: const TextStyle(fontSize: 13, color: TransovaTheme.onSurfaceVariant)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            priority,
            style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _FleetAndSummaryPanel extends StatelessWidget {
  const _FleetAndSummaryPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TransovaTheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Fleet Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              _buildStatusRow('Active Vehicles', '38', Colors.white),
              const SizedBox(height: 12),
              _buildStatusRow('In Maintenance', '4', Colors.white70),
              const SizedBox(height: 12),
              _buildStatusRow('Standby', '2', Colors.white70),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TransovaTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Efficiency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TransovaTheme.primary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBar(0.4),
                    _buildBar(0.7),
                    _buildBar(0.6),
                    _buildBar(0.9),
                    _buildBar(0.8),
                    _buildBar(0.5),
                    _buildBar(0.3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color)),
        Text(count, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBar(double heightFactor) {
    return Container(
      width: 12,
      decoration: BoxDecoration(
        color: TransovaTheme.secondary,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(heightFactor: heightFactor),
    );
  }
}