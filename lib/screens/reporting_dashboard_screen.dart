import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'admin_analytics_screen.dart';

class ReportingDashboardScreen extends StatefulWidget {
  final AuthService authService;
  const ReportingDashboardScreen({super.key, required this.authService});

  @override
  State<ReportingDashboardScreen> createState() => _ReportingDashboardScreenState();
}

class _ReportingDashboardScreenState extends State<ReportingDashboardScreen> {
  int _currentMobileNavIndex = 3;

  void _onNavTap(int index) {
    if (index == _currentMobileNavIndex) return;

    final user = widget.authService.currentUser;
    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = DashboardScreen(authService: widget.authService);
        break;
      case 1:
        nextScreen = RequestTransportScreen(authService: widget.authService);
        break;
      case 2:
        nextScreen = FleetMaintenanceScreen(authService: widget.authService);
        break;
      case 3:
        if (user?.role == UserRole.admin) {
          nextScreen = AdminAnalyticsScreen(authService: widget.authService);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required')));
          return;
        }
        break;
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
    final isAuthorized = user?.role == UserRole.admin || user?.role == UserRole.manager;

    // SECURITY GUARD: Only Admin/Manager can see operational reports
    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Restricted Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Safety')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TransovaTheme.background,
      appBar: _buildHeader(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OPERATIONAL OVERVIEW',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Reporting Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TransovaTheme.primary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffd5ecf8),
                          foregroundColor: TransovaTheme.onSurface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: const Text('Last 30 Days', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff000666),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.file_download_outlined, size: 16),
                        label: const Text('Export', style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildMetricCard(
                    icon: Icons.shuffle,
                    title: 'TOTAL TRIPS',
                    value: '2,842',
                    label: 'completed',
                    badgeText: '+12.5%',
                    isPositiveBadge: true,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricCard(
                    icon: Icons.payments_outlined,
                    title: 'TOTAL REVENUE',
                    value: '\$412.8k',
                    label: 'USD',
                    badgeText: '+8.2%',
                    isPositiveBadge: true,
                  ),
                  const SizedBox(height: 16),
                  _buildMetricCard(
                    icon: Icons.gpp_good_outlined,
                    title: 'FLEET HEALTH',
                    value: '94.2%',
                    label: 'operational',
                    badgeText: '-2 units',
                    isPositiveBadge: false,
                  ),
                  const SizedBox(height: 24),
                  _buildFuelEfficiencyTrendsCard(),
                  const SizedBox(height: 24),
                  _buildTripCompletionRatesCard(),
                  const SizedBox(height: 24),
                  _buildTopDriversSection(),
                  const SizedBox(height: 24),
                  _buildRecentAlertsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const Border(bottom: BorderSide(color: TransovaTheme.outlineVariant, width: 1)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: TransovaTheme.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'TRANSOVA',
        style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, letterSpacing: -0.5),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: TransovaTheme.primary),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 18,
          backgroundColor: TransovaTheme.primary,
          child: const Text('AS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String label,
    required String badgeText,
    required bool isPositiveBadge,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffe6f6ff),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TransovaTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TransovaTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: TransovaTheme.primary, size: 20),
              ),
              const SizedBox(height: 20),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TransovaTheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 14, color: TransovaTheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPositiveBadge ? const Color(0xff5cfd80) : const Color(0xffffdad6),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPositiveBadge ? const Color(0xff00531e) : const Color(0xff93000a),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFuelEfficiencyTrendsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: TransovaTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Fuel Efficiency Trends', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
                ],
              ),
              Text('MPG Avg', style: TextStyle(fontSize: 12, color: TransovaTheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(painter: FuelTrendLinePainter()),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Mon', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
              Text('Tue', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
              Text('Wed', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
              Text('Thu', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
              Text('Fri', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
              Text('Sat', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
              Text('Sun', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTripCompletionRatesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: TransovaTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Trip Completion\nRates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TransovaTheme.primary, height: 1.2)),
                ],
              ),
              Row(
                children: [
                  _buildLegendIndicator(const Color(0xff000666), 'On\nTime'),
                  const SizedBox(width: 12),
                  _buildLegendIndicator(const Color(0xff006e2a), 'Delayed'),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(painter: DonutChartPainter()),
                  ),
                  const Column(
                    children: [
                      Text('88%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
                      Text('Target', style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
                    ],
                  )
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildDonutLabelTile('2,490', 'On-Schedule', const Color(0xffdbf1fe)),
                    const SizedBox(height: 12),
                    _buildDonutLabelTile('352', 'Minor Delays', const Color(0xffe6f6ff)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: TransovaTheme.onSurface, height: 1.1)),
      ],
    );
  }

  Widget _buildDonutLabelTile(String value, String description, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
          Text(description, style: const TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildTopDriversSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Performing Drivers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All', style: TextStyle(fontSize: 13, color: TransovaTheme.primary, fontWeight: FontWeight.w500)),
                )
              ],
            ),
          ),
          const Divider(height: 1, color: TransovaTheme.outlineVariant),
          _buildDriverRow('Marcus Thorne', '98.4% Efficiency • 42 Trips', '4.98'),
          const Divider(height: 1, color: TransovaTheme.outlineVariant),
          _buildDriverRow('Sarah Jenkins', '97.8% Efficiency • 38 Trips', '4.95'),
        ],
      ),
    );
  }

  Widget _buildDriverRow(String name, String metrics, String score) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.center,
            child: const Text('img', style: TextStyle(color: Colors.black54, fontSize: 11)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TransovaTheme.onSurface)),
                const SizedBox(height: 2),
                Text(metrics, style: const TextStyle(fontSize: 12, color: TransovaTheme.onSurfaceVariant)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_border, color: Color(0xff006e2a), size: 16),
              const SizedBox(width: 4),
              Text(score, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff006e2a))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffe6f6ff),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TransovaTheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Fleet Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xffba1a1a), borderRadius: BorderRadius.circular(4)),
                child: const Text('3 URGENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildAlertNotificationItem(
            icon: Icons.warning_amber_rounded,
            accentColor: const Color(0xffba1a1a),
            bgColor: const Color(0xffffdad6).withValues(alpha: 0.4),
            title: 'Engine Fault: Unit TR-422',
            description: 'Critical pressure drop detected in fuel line. Maintenance required immediately.',
            timeAgo: '12 minutes ago',
          ),
          const SizedBox(height: 12),
          _buildAlertNotificationItem(
            icon: Icons.access_time,
            accentColor: const Color(0xff705d00),
            bgColor: const Color(0xffffe170).withValues(alpha: 0.3),
            title: 'Scheduled Maintenance Due',
            description: 'Unit TR-109 has reached 15,000 miles since last service.',
            timeAgo: '2 hours ago',
          ),
        ],
      ),
    );
  }

  Widget _buildAlertNotificationItem({
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required String title,
    required String description,
    required String timeAgo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 5, height: 110, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: accentColor, size: 18),
                      const SizedBox(width: 8),
                      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(description, style: const TextStyle(fontSize: 12, color: TransovaTheme.onSurface, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(timeAgo, style: const TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentMobileNavIndex,
      backgroundColor: TransovaTheme.surfaceContainer,
      indicatorColor: TransovaTheme.secondaryContainer,
      onDestinationSelected: _onNavTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'HOME',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          label: 'BOOKINGS',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'FLEET',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          label: 'REPORTS',
        ),
      ],
    );
  }
}

class FuelTrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = TransovaTheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.6);
    path.lineTo(size.width * 0.16, size.height * 0.4);
    path.lineTo(size.width * 0.33, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height * 0.25);
    path.lineTo(size.width * 0.66, size.height * 0.55);
    path.lineTo(size.width * 0.83, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.45);

    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 10;
    const strokeWidth = 14.0;

    final paintPrimary = Paint()
      ..color = const Color(0xff000666)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintSecondary = Paint()
      ..color = const Color(0xff006e2a)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi * 1.4, false, paintPrimary);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.9, math.pi * 0.5, false, paintSecondary);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}