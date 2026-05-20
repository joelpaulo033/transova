import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'sanitation_ops_screen.dart';
import 'live_tracking_screen.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  final AuthService authService;
  const AdminAnalyticsScreen({super.key, required this.authService});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int _currentNavIndex = 3;
  bool _showUserManagement = false;

  // Helper for TZS conversion: $1 USD = 2600 TZS
  String formatCurrency(double usdAmount) {
    double tzsAmount = usdAmount * 2600;
    return 'TZS ${tzsAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    final user = widget.authService.currentUser;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = DashboardScreen(authService: widget.authService);
        break;
      case 1:
        nextScreen = const RequestTransportScreen();
        break;
      case 2:
        nextScreen = const FleetMaintenanceScreen();
        break;
      case 3:
      // Double security check for navigation
        if (user?.role != UserRole.admin) return;
        return;
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
    final user = widget.authService.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isAdmin = user?.role == UserRole.admin;

    // SECURITY GUARD: Only Admins can see this screen
    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Access Denied: Admin Rights Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Return to Safety')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TransovaTheme.background,
      body: Row(
        children: [
          if (isDesktop) _DesktopNavigationSidebarWidget(
            authService: widget.authService,
            onUserManagementToggle: (show) => setState(() => _showUserManagement = show),
            isUserManagementSelected: _showUserManagement,
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopAppBarWidget(context, isDesktop),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: _showUserManagement
                            ? _UserManagementSection(authService: widget.authService)
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetricCardsBentoGridWidget(formatter: formatCurrency),
                            const SizedBox(height: 24),
                            if (isDesktop)
                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 8, child: _GlobalFleetMapWidget()),
                                  SizedBox(width: 24),
                                  Expanded(flex: 4, child: _FleetStatusListWidget()),
                                ],
                              )
                            else
                              const Column(
                                children: [
                                  _GlobalFleetMapWidget(),
                                  SizedBox(height: 24),
                                  _FleetStatusListWidget(),
                                ],
                              ),
                            const SizedBox(height: 24),
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _RevenueTrendsChartWidget(formatter: formatCurrency)),
                                  const SizedBox(width: 24),
                                  const Expanded(child: _CriticalOperationsWidget()),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _RevenueTrendsChartWidget(formatter: formatCurrency),
                                  const SizedBox(height: 24),
                                  const _CriticalOperationsWidget(),
                                ],
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: TransovaTheme.surface,
        indicatorColor: TransovaTheme.secondaryContainer,
        onDestinationSelected: _onNavTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_note), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Fleet'),
          NavigationDestination(icon: Icon(Icons.analytics), label: 'Admin'),
        ],
      ),
    );
  }

  Widget _buildTopAppBarWidget(BuildContext context, bool isDesktop) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: TransovaTheme.surface,
        border: Border(bottom: BorderSide(color: TransovaTheme.outlineVariant, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (!isDesktop) ...[
                const Icon(Icons.menu, color: TransovaTheme.primary),
                const SizedBox(width: 16),
              ],
              Text(
                _showUserManagement ? 'User Management' : 'Analytics Overview',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TransovaTheme.onSurface),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.search, color: TransovaTheme.onSurfaceVariant), onPressed: () {}),
              IconButton(icon: const Icon(Icons.notifications_outlined, color: TransovaTheme.onSurfaceVariant), onPressed: () {}),
              if (isDesktop) ...[
                Container(width: 1, height: 24, color: TransovaTheme.outlineVariant, margin: const EdgeInsets.symmetric(horizontal: 16)),
                const Text('March 24, 2024', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
              ]
            ],
          )
        ],
      ),
    );
  }
}

class _DesktopNavigationSidebarWidget extends StatelessWidget {
  final AuthService authService;
  final Function(bool) onUserManagementToggle;
  final bool isUserManagementSelected;

  const _DesktopNavigationSidebarWidget({
    required this.authService,
    required this.onUserManagementToggle,
    required this.isUserManagementSelected,
  });

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    return Container(
      width: 320,
      color: TransovaTheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text(
              'TRANSOVA',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: TransovaTheme.primary, letterSpacing: -0.5),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: TransovaTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: Colors.blueGrey[100], child: const Icon(Icons.person, color: TransovaTheme.primary)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.displayName ?? 'Admin User', style: const TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onSurface, fontSize: 16)),
                    Text(user?.role.name.toUpperCase() ?? 'ADMIN', style: const TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              children: [
                _buildSidebarItem(context, icon: Icons.grid_view, label: 'Dashboard', screen: DashboardScreen(authService: authService)),
                _buildSidebarItem(context, icon: Icons.map, label: 'Fleet Tracking', screen: const LiveTrackingScreen()),
                _buildSidebarItem(context, icon: Icons.event_note, label: 'Bookings', screen: const RequestTransportScreen()),
                _buildSidebarItem(context, icon: Icons.analytics, label: 'Analytics', isSelected: !isUserManagementSelected, onTap: () => onUserManagementToggle(false)),
                _buildSidebarItem(context, icon: Icons.people, label: 'User Management', isSelected: isUserManagementSelected, onTap: () => onUserManagementToggle(true)),
                _buildSidebarItem(context, icon: Icons.delete_sweep, label: 'Sanitation Ops', screen: const SanitationOpsScreen()),
                const Spacer(),
                _buildSidebarItem(context, icon: Icons.settings, label: 'Settings'),
                _buildSidebarItem(context, icon: Icons.logout, label: 'Logout', onTap: () => authService.logout()),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, {required IconData icon, required String label, bool isSelected = false, Widget? screen, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? TransovaTheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : TransovaTheme.onSurfaceVariant),
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : TransovaTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
        dense: true,
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
}

class _UserManagementSection extends StatelessWidget {
  final AuthService authService;
  const _UserManagementSection({required this.authService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Manage Users', style: Theme.of(context).textTheme.headlineMedium),
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Staff'),
              style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: TransovaTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildUserRow(context, 'John Doe', 'john@transova.com', UserRole.driver),
              _buildUserRow(context, 'Jane Smith', 'jane@transova.com', UserRole.manager),
              _buildUserRow(context, 'Mike Johnson', 'mike@transova.com', UserRole.driver),
              _buildUserRow(context, 'Alice Brown', 'alice@customer.com', UserRole.customer),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(BuildContext context, String name, String email, UserRole role) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$email • ${role.name.toUpperCase()}'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
          const PopupMenuItem(value: 'edit', child: Text('Edit Role')),
          const PopupMenuItem(value: 'delete', child: Text('Deactivate', style: TextStyle(color: TransovaTheme.error))),
        ],
        onSelected: (value) {
          if (value == 'reset') {
            authService.resetPassword(email);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password reset link sent to $email')));
          }
        },
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    UserRole selectedRole = UserRole.driver;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Register Staff (Driver/Manager)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 16),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                items: [UserRole.driver, UserRole.manager].map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))).toList(),
                onChanged: (val) => setDialogState(() => selectedRole = val!),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                authService.adminCreateUser(emailController.text, nameController.text, selectedRole);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User registered successfully')));
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardsBentoGridWidget extends StatelessWidget {
  final String Function(double) formatter;
  const _MetricCardsBentoGridWidget({required this.formatter});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1024 ? 2 : 4);
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.5,
        children: [
          _buildMetricCard(icon: Icons.payments, value: formatter(164.97), title: 'Total Revenue', trend: '+12.5%', isErrorCard: false),
          _buildMetricCard(icon: Icons.local_shipping, value: '94.2%', title: 'Vehicle Utilization', trend: 'Optimal', isErrorCard: false),
          _buildMetricCard(icon: Icons.assignment, value: '1,284', title: 'Active Bookings', trend: 'Live', isErrorCard: false),
          _buildMetricCard(icon: Icons.warning, value: '08', title: 'System Alerts', trend: 'Critical', isErrorCard: true),
        ],
      );
    });
  }

  Widget _buildMetricCard({required IconData icon, required String value, required String title, required String trend, required bool isErrorCard}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isErrorCard ? const Color(0xFFFFDAD6).withOpacity(0.3) : TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isErrorCard ? const Color(0xFFBA1A1A).withOpacity(0.2) : TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isErrorCard ? const Color(0xFFBA1A1A) : TransovaTheme.primaryContainer.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: isErrorCard ? Colors.white : TransovaTheme.primary),
              ),
              Text(trend, style: TextStyle(color: isErrorCard ? const Color(0xFFBA1A1A) : TransovaTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isErrorCard ? const Color(0xFFBA1A1A) : TransovaTheme.primary, height: 1.25)),
            ],
          )
        ],
      ),
    );
  }
}

class _GlobalFleetMapWidget extends StatelessWidget {
  const _GlobalFleetMapWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Container(
            color: Colors.grey[300],
            width: double.infinity,
            height: double.infinity,
            child: const Center(
              child: Icon(Icons.map_outlined, size: 64, color: TransovaTheme.onSurfaceVariant),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white.withOpacity(0.7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Real-time Fleet Map', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, fontSize: 16)),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: TransovaTheme.primary),
                        onPressed: () {},
                        child: const Text('Global View', style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Local', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _FleetStatusListWidget extends StatelessWidget {
  const _FleetStatusListWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fleet Status', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, fontSize: 16)),
          const Text('Live vehicle telemetry', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildVehicleTile(context, id: 'TRK-8829', model: 'Mercedes Actros', status: 'In Transit', extra: 'ETA: 12m', isTransit: true),
                _buildVehicleTile(context, id: 'TRK-1044', model: 'Volvo FH16', status: 'Available', extra: 'Terminal A', isTransit: false, isAvailable: true),
                _buildVehicleTile(context, id: 'TRK-9902', model: 'Scania R500', status: 'Maintenance', extra: 'Low Fuel', isTransit: false, isMaintenance: true),
                _buildVehicleTile(context, id: 'TRK-5521', model: 'Freightliner', status: 'In Transit', extra: 'ETA: 45m', isTransit: true),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildVehicleTile(BuildContext context, {required String id, required String model, required String status, required String extra, required bool isTransit, bool isAvailable = false, bool isMaintenance = false}) {
    Color badgeBg = TransovaTheme.surfaceContainerHigh;
    Color badgeText = TransovaTheme.onSurfaceVariant;

    if (isTransit) {
      badgeBg = TransovaTheme.secondaryContainer.withOpacity(0.3);
      badgeText = TransovaTheme.onSecondaryContainer;
    } else if (isMaintenance) {
      badgeBg = const Color(0xFFFFDAD6);
      badgeText = const Color(0xFF93000A);
    }

    return InkWell(
      onTap: () {
        if (isTransit) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveTrackingScreen()));
        } else if (isMaintenance) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FleetMaintenanceScreen()));
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: TransovaTheme.outlineVariant.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: isMaintenance ? const Color(0xFFBA1A1A) : TransovaTheme.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onSurface, fontSize: 14)),
                    Text(model, style: const TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
                  ],
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(status, style: TextStyle(color: badgeText, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 4),
                Text(extra, style: TextStyle(fontSize: 11, color: isMaintenance ? const Color(0xFFBA1A1A) : TransovaTheme.onSurfaceVariant)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _RevenueTrendsChartWidget extends StatelessWidget {
  final String Function(double) formatter;
  const _RevenueTrendsChartWidget({required this.formatter});

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue Trends', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, fontSize: 16)),
                  Text('Last 7 days performance', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
                ],
              ),
              Text('Weekly', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 192,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(heightPercentage: 0.40, label: formatter(8.46)),
                _buildBar(heightPercentage: 0.65, label: formatter(13.46)),
                _buildBar(heightPercentage: 0.55, label: formatter(11.53)),
                _buildBar(heightPercentage: 0.85, label: formatter(18.46)),
                _buildBar(heightPercentage: 0.95, label: formatter(20.76), isActive: true),
                _buildBar(heightPercentage: 0.70, label: formatter(14.61)),
                _buildBar(heightPercentage: 0.60, label: formatter(12.69)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('MON', style: TextStyle(fontSize: 10)),
              Text('TUE', style: TextStyle(fontSize: 10)),
              Text('WED', style: TextStyle(fontSize: 10)),
              Text('THU', style: TextStyle(fontSize: 10)),
              Text('FRI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
              Text('SAT', style: TextStyle(fontSize: 10)),
              Text('SUN', style: TextStyle(fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBar({required double heightPercentage, required String label, bool isActive = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: FractionallySizedBox(
          heightFactor: heightPercentage,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(label, style: TextStyle(fontSize: 8, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? TransovaTheme.primary : TransovaTheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive ? TransovaTheme.primary : TransovaTheme.primaryContainer.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CriticalOperationsWidget extends StatelessWidget {
  const _CriticalOperationsWidget();

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
          const Text('Critical Operations', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, fontSize: 16)),
          const SizedBox(height: 24),
          _buildAlertRow(context, icon: Icons.thermostat, title: 'TRK-8829: High Temp', desc: 'Engine temperature exceeds 105°C', actionText: 'CONTACT', alertColor: const Color(0xFFBA1A1A)),
          const SizedBox(height: 12),
          _buildAlertRow(context, icon: Icons.ev_station, title: 'TRK-9902: Low Fuel', desc: 'Less than 15% capacity remaining', actionText: 'REDIRECT', alertColor: const Color(0xFF705D00)),
          const SizedBox(height: 12),
          _buildAlertRow(context, icon: Icons.route, title: 'Route Divergence', desc: 'TRK-5521 moved off planned path', actionText: 'VIEW', alertColor: TransovaTheme.primary),
        ],
      ),
    );
  }

  Widget _buildAlertRow(BuildContext context, {required IconData icon, required String title, required String desc, required String actionText, required Color alertColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: alertColor, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: alertColor),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onSurface, fontSize: 14)),
                  Text(desc, style: const TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 11)),
                ],
              )
            ],
          ),
          TextButton(
            onPressed: () {
              if (title.contains('TRK-8829')) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LiveTrackingScreen()));
              }
            },
            child: Text(actionText, style: TextStyle(color: alertColor, fontWeight: FontWeight.bold, fontSize: 11)),
          )
        ],
      ),
    );
  }
}