import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'request_transport_screen.dart';
import 'live_tracking_screen.dart';
import 'sanitation_ops_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'admin_analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AuthService authService;
  const DashboardScreen({super.key, required this.authService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  // Helper for TZS conversion: $1 USD = 2600 TZS
  String formatCurrency(double usdAmount) {
    double tzsAmount = usdAmount * 2600;
    // FIXED: Used double quotes for the inner RegExp pattern to avoid syntax errors
    return 'TZS ${tzsAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  void _protectedAction(VoidCallback action) {
    final role = widget.authService.currentUser?.role ?? UserRole.guest;
    if (role == UserRole.guest) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account Required'),
          content: const Text('Please register or log in to access advanced features like bookings.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.authService.logout();
              },
              child: const Text('Login / Register'),
            ),
          ],
        ),
      );
    } else {
      action();
    }
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

    Widget? nextScreen;
    switch (index) {
      case 0:
        return; // Already here
      case 1:
        _protectedAction(() {
          Navigator.push(context, MaterialPageRoute(builder: (context) => RequestTransportScreen(authService: widget.authService)));
        });
        return;
      case 2:
        _protectedAction(() {
          nextScreen = FleetMaintenanceScreen(authService: widget.authService);
        });
        break;
      case 3:
        if (widget.authService.currentUser?.role == UserRole.admin) {
          nextScreen = AdminAnalyticsScreen(authService: widget.authService);
        } else {
          // Placeholder for Account/Profile screen
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Screen coming soon')));
          return;
        }
        break;
      default:
        return;
    }

    if (nextScreen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isAdmin = user?.role == UserRole.admin || user?.role == UserRole.manager;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TransovaTheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'TRANSOVA',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            color: TransovaTheme.primary,
            letterSpacing: -0.5,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: TransovaTheme.primary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: TransovaTheme.onSurfaceVariant),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: TransovaTheme.primary),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: TransovaTheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: TransovaTheme.outlineVariant, height: 1.0),
        ),
      ),
      drawer: _buildDrawer(context),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeHeaderWidget(userName: user?.displayName ?? 'Guest'),
                    const SizedBox(height: 24),

                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: Column(
                              children: [
                                _QuickBookingBentoGrid(onAction: _protectedAction, authService: widget.authService),
                                const SizedBox(height: 24),
                                _ActiveTrackingCardWidget(authService: widget.authService),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _RecentActivityListWidget(formatter: formatCurrency),
                                const SizedBox(height: 24),
                                const _PromoBannerCardWidget(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _QuickBookingBentoGrid(onAction: _protectedAction, authService: widget.authService),
                          const SizedBox(height: 24),
                          _ActiveTrackingCardWidget(authService: widget.authService),
                          const SizedBox(height: 24),
                          _RecentActivityListWidget(formatter: formatCurrency),
                          const SizedBox(height: 24),
                          const _PromoBannerCardWidget(),
                        ],
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: TransovaTheme.secondary,
        onPressed: () => _protectedAction(() {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RequestTransportScreen(authService: widget.authService)),
          );
        }),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: const Text('New Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width >= 768
          ? null
          : NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: TransovaTheme.surface,
        indicatorColor: TransovaTheme.secondaryContainer,
        onDestinationSelected: _onNavTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: TransovaTheme.onSecondaryContainer),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_note),
            label: 'Bookings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Fleet',
          ),
          NavigationDestination(
            icon: Icon(isAdmin ? Icons.analytics : Icons.person_outline),
            label: isAdmin ? 'Admin' : 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = widget.authService.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: TransovaTheme.primary),
            accountName: Text(user?.displayName ?? 'Guest User'),
            accountEmail: Text(user?.email ?? 'Sign in to access more features'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: TransovaTheme.primary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Request Transport'),
            onTap: () {
              Navigator.pop(context);
              _protectedAction(() {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RequestTransportScreen(authService: widget.authService)));
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Sanitation Operations'),
            onTap: () {
              Navigator.pop(context);
              _protectedAction(() {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SanitationOpsScreen(authService: widget.authService)));
              });
            },
          ),
          if (user?.role == UserRole.admin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAnalyticsScreen(authService: widget.authService)));
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(user?.role == UserRole.guest ? 'Login / Register' : 'Logout'),
            onTap: () {
              Navigator.pop(context);
              widget.authService.logout();
            },
          ),
        ],
      ),
    );
  }
}

class _WelcomeHeaderWidget extends StatelessWidget {
  final String userName;
  const _WelcomeHeaderWidget({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $userName', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('Manage your transport and sanitation operations.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: TransovaTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: TransovaTheme.secondary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text('Fleet Status: Optimal', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: TransovaTheme.onSurface, fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    );
  }
}

class _QuickBookingBentoGrid extends StatelessWidget {
  final Function(VoidCallback) onAction;
  final AuthService authService;
  const _QuickBookingBentoGrid({required this.onAction, required this.authService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Booking', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildBentoButton(
              context: context,
              title: 'Wedding',
              subtitle: 'Luxury Fleet',
              icon: Icons.celebration,
              bgColor: TransovaTheme.primaryContainer,
              textColor: Colors.white,
              onTap: () => onAction(() => Navigator.push(context, MaterialPageRoute(builder: (context) => RequestTransportScreen(authService: authService)))),
            ),
            _buildBentoButton(
              context: context,
              title: 'Funeral',
              subtitle: 'Solemn Service',
              icon: Icons.church,
              bgColor: TransovaTheme.surfaceContainerHighest,
              textColor: TransovaTheme.primary,
              borderColor: TransovaTheme.outlineVariant,
              onTap: () => onAction(() => Navigator.push(context, MaterialPageRoute(builder: (context) => RequestTransportScreen(authService: authService)))),
            ),
            _buildLongBentoCard(
              context: context,
              title: 'Airport Transfer',
              subtitle: 'Scheduled pickup & drop',
              icon: Icons.flight_takeoff,
              onTap: () => onAction(() => Navigator.push(context, MaterialPageRoute(builder: (context) => RequestTransportScreen(authService: authService)))),
            ),
            _buildSanitationContainer(context),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 36, color: textColor),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 12)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLongBentoCard({required BuildContext context, required String title, required String subtitle, required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TransovaTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TransovaTheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: TransovaTheme.primaryFixed, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.flight_takeoff, color: TransovaTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TransovaTheme.onSurface)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: TransovaTheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: TransovaTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildSanitationContainer(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onAction(() => Navigator.push(context, MaterialPageRoute(builder: (context) => SanitationOpsScreen(authService: authService)))),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: TransovaTheme.secondaryContainer, borderRadius: BorderRadius.circular(24)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.delete_sweep, size: 28, color: TransovaTheme.onSecondaryContainer),
                  Text('Waste\nCollection', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onSecondaryContainer, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () => onAction(() => Navigator.push(context, MaterialPageRoute(builder: (context) => SanitationOpsScreen(authService: authService)))),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: TransovaTheme.tertiaryContainer, borderRadius: BorderRadius.circular(24)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.propane_tank, size: 28, color: TransovaTheme.onTertiaryContainer),
                  Text('Tank\nEmptying', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onTertiaryContainer, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveTrackingCardWidget extends StatelessWidget {
  final AuthService authService;
  const _ActiveTrackingCardWidget({required this.authService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            color: Colors.grey[300],
            child: Stack(
              children: [
                const Center(child: Icon(Icons.map, size: 48, color: TransovaTheme.onSurfaceVariant)),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: TransovaTheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        Icon(Icons.local_shipping, size: 16, color: TransovaTheme.onSecondaryContainer),
                        SizedBox(width: 4),
                        Text('IN TRANSIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: TransovaTheme.onSecondaryContainer)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Luxury Wedding Fleet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: TransovaTheme.primary)),
                        Text('Order #TS-98421 • Scheduled for 10:30 AM', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Arriving in 12 min', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.secondary, fontSize: 16)),
                        Text('Distance: 4.2 km', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TransovaTheme.background,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: TransovaTheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundColor: Colors.blueGrey[100], child: const Icon(Icons.person)),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR DRIVER', style: TextStyle(fontSize: 10, letterSpacing: 0.5, color: TransovaTheme.onSurfaceVariant)),
                            Text('Samuel Thompson', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: TransovaTheme.onSurface)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: TransovaTheme.primary),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: TransovaTheme.surfaceContainerHigh,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chat, color: TransovaTheme.primary),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: TransovaTheme.surfaceContainerHigh,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TransovaTheme.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LiveTrackingScreen(authService: authService)));
                  },
                  icon: const Icon(Icons.map, color: Colors.white),
                  label: const Text('Track on Map', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _RecentActivityListWidget extends StatelessWidget {
  final String Function(double) formatter;
  const _RecentActivityListWidget({required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: TransovaTheme.primary))),
          ],
        ),
        const SizedBox(height: 8),
        _buildActivityItem(title: 'Corporate Airport Shuttle', date: 'Oct 24, 2023', price: formatter(45.00), status: 'Completed', icon: Icons.local_shipping, isCustomIconBg: false),
        const SizedBox(height: 12),
        _buildActivityItem(title: 'Weekly Waste Collection', date: 'Oct 22, 2023', price: formatter(12.50), status: 'Completed', icon: Icons.delete_sweep, isCustomIconBg: true),
        const SizedBox(height: 12),
        _buildActivityItem(title: 'Funeral Service Escort', date: 'Oct 18, 2023', price: formatter(180.00), status: 'Completed', icon: Icons.local_shipping, isCustomIconBg: false),
      ],
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String date,
    required String price,
    required String status,
    required IconData icon,
    required bool isCustomIconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCustomIconBg ? TransovaTheme.secondaryContainer : TransovaTheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: isCustomIconBg ? TransovaTheme.onSecondaryContainer : TransovaTheme.primary, size: 20),
              ),
              Text(date, style: const TextStyle(fontSize: 12, color: TransovaTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onSurface)),
                  Text(status, style: const TextStyle(fontSize: 12, color: TransovaTheme.onSurfaceVariant)),
                ],
              ),
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }
}

class _PromoBannerCardWidget extends StatelessWidget {
  const _PromoBannerCardWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TransovaTheme.primary,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Go Premium', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Get 15% off on all sanitation services this month.', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TransovaTheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {},
                child: const Text('UPGRADE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              )
            ],
          ),
          const Positioned(
            right: -16,
            bottom: -16,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.workspace_premium, size: 100, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}