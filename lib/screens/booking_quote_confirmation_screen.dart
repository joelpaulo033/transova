import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'admin_analytics_screen.dart';
import 'active_trip_screen.dart';

class BookingQuoteConfirmationScreen extends StatefulWidget {
  final AuthService? authService;
  const BookingQuoteConfirmationScreen({super.key, this.authService});

  @override
  State<BookingQuoteConfirmationScreen> createState() => _BookingQuoteConfirmationScreenState();
}

enum InsuranceOption { standard, premium }

class _BookingQuoteConfirmationScreenState extends State<BookingQuoteConfirmationScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('bookings/active');
  int _currentMobileNavIndex = 1;
  InsuranceOption _selectedInsurance = InsuranceOption.standard;
  bool _isProcessingTransaction = false;
  bool _showSuccessOverlay = false;

  final double _baseFreightCharge = 1245.00;
  final double _fuelSurcharge = 186.75;
  final double _serviceFee = 45.00;
  final double _premiumInsuranceCost = 85.00;

  double get _totalQuote {
    double total = _baseFreightCharge + _fuelSurcharge + _serviceFee;
    if (_selectedInsurance == InsuranceOption.premium) {
      total += _premiumInsuranceCost;
    }
    return total;
  }

  String formatCurrency(double usdAmount) {
    double tzsAmount = usdAmount * 2600;
    return 'TZS ${tzsAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  void _triggerConfirmationWorkflow() async {
    setState(() {
      _isProcessingTransaction = true;
    });

    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      setState(() {
        _isProcessingTransaction = false;
        _showSuccessOverlay = true;
      });
    }
  }

  void _onNavTap(int index) {
    if (index == _currentMobileNavIndex) return;
    final user = widget.authService?.currentUser;

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = DashboardScreen(authService: widget.authService!);
        break;
      case 1:
        return;
      case 2:
        nextScreen = const FleetMaintenanceScreen();
        break;
      case 3:
        if (user?.role == UserRole.admin) {
          nextScreen = AdminAnalyticsScreen(authService: widget.authService!);
        } else {
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
    final user = widget.authService?.currentUser;

    // SECURITY GUARD: Guest users cannot confirm bookings
    if (user?.role == UserRole.guest || user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Account Required to Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Login')),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<DatabaseEvent>(
        stream: _dbRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Scaffold(
              backgroundColor: TransovaTheme.background,
              appBar: AppBar(title: const Text("Booking Confirmation")),
              body: const Center(child: Text("No active booking found.")),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth >= 1024;

              return Stack(
                children: [
                  Scaffold(
                    backgroundColor: TransovaTheme.background,
                    appBar: _buildAdaptiveHeader(isDesktop),
                    bottomNavigationBar: isDesktop ? null : _buildMobileBottomNavigationBar(),
                    body: SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isDesktop)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 7, child: _buildRouteAndMapColumn()),
                                      const SizedBox(width: 24),
                                      Expanded(flex: 5, child: _buildPaymentSummaryColumn()),
                                    ],
                                  )
                                else ...[
                                  _buildRouteAndMapColumn(),
                                  const SizedBox(height: 24),
                                  _buildPaymentSummaryColumn(),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showSuccessOverlay) _buildSuccessModalStateOverlay(),
                ],
              );
            },
          );
        }
    );
  }

  PreferredSizeWidget _buildAdaptiveHeader(bool isDesktop) {
    return AppBar(
      backgroundColor: TransovaTheme.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shape: const Border(bottom: BorderSide(color: TransovaTheme.outlineVariant, width: 1)),
      titleSpacing: isDesktop ? 32 : 16,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: TransovaTheme.onSurfaceVariant),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Text(
            'TRANSOVA',
            style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, letterSpacing: -0.5),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 48),
            _buildDesktopNavigationMenu(),
          ]
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: TransovaTheme.onSurfaceVariant),
          onPressed: () {},
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 20,
          backgroundColor: TransovaTheme.primaryFixedDim,
          child: const Icon(Icons.person, color: TransovaTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildDesktopNavigationMenu() {
    return Row(
      children: [
        _menuTextButton('Home', active: false, screen: DashboardScreen(authService: widget.authService!)),
        _menuTextButton('Bookings', active: true),
        _menuTextButton('Fleet', active: false, screen: const FleetMaintenanceScreen()),
        _menuTextButton('Reports', active: false, screen: AdminAnalyticsScreen(authService: widget.authService!)),
      ],
    );
  }

  Widget _menuTextButton(String title, {required bool active, Widget? screen}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: active ? TransovaTheme.surfaceContainerLow : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          if (screen != null) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => screen));
          }
        },
        child: Text(
          title,
          style: TextStyle(
            color: active ? TransovaTheme.primary : TransovaTheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteAndMapColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TransovaTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Route Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: TransovaTheme.primary)),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.location_on, color: TransovaTheme.primary, size: 22),
                          Container(width: 2, height: 40, color: TransovaTheme.outlineVariant),
                          const Icon(Icons.flag, color: TransovaTheme.secondary, size: 22),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('PICKUP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
                            Text('142 Industrial Way, Port Logistics Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            SizedBox(height: 24),
                            Text('DESTINATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
                            Text('447 West Central Distribution, Metro City', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: TransovaTheme.outlineVariant),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('EST. ARRIVAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Today, 16:45', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: TransovaTheme.primary, height: 1.25)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VEHICLE CLASS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.local_shipping, color: TransovaTheme.onSurfaceVariant, size: 20),
                                SizedBox(width: 8),
                                Text('Class 8 Heavy Duty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: TransovaTheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'ESTIMATED QUOTE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TransovaTheme.onSecondaryContainer),
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 256,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
            image: const DecorationImage(
              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuBnsZ5h--yLcrackIZR0b0pI5aivwLjtHK4moa2pF0lqAY_6Wn_iBD_hi3h3XnKXan7EuEwYcOqnCiIRXSmU6JoKtqg5lTdY6SiICFpynvM5mdg6vZ9WJVXIkbQosdIPAgmM1SddLQGhPVqh3c85ehlrVngimHTnlRGk1Cph-r48CH0j148D1QhzTNpzgPcppguTq9BNYELyJm22JKpbK-1ZJAHnO1lbIHujgMb-aqUzw5pKFbeVkERWAnFF6MctPp3a6B247znVC9E'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                bottom: 16,
                left: 16,
                child: Card(
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: TransovaTheme.secondary, size: 12),
                        SizedBox(width: 8),
                        Text('Live Traffic Optimized', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurface)),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPaymentSummaryColumn() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: TransovaTheme.primary)),
          const SizedBox(height: 24),
          _buildReceiptRow('Base Freight Charge', _baseFreightCharge),
          const SizedBox(height: 16),
          _buildReceiptRow('Fuel Surcharge', _fuelSurcharge),
          const SizedBox(height: 16),
          _buildReceiptRow('Service Fee', _serviceFee),
          const SizedBox(height: 24),
          const Divider(color: TransovaTheme.outlineVariant),
          const SizedBox(height: 16),
          const Text('INSURANCE OPTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          _buildInsuranceCardOption(
            option: InsuranceOption.standard,
            title: 'Standard Liability',
            subtitle: 'Up to TZS 130M coverage',
            trailingText: 'Included',
            isFree: true,
          ),
          const SizedBox(height: 12),
          _buildInsuranceCardOption(
            option: InsuranceOption.premium,
            title: 'Premium Protection',
            subtitle: 'Full cargo value + delay protection',
            trailingText: '+ ${formatCurrency(85.00)}',
            isFree: false,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: TransovaTheme.primary, width: 2, style: BorderStyle.solid)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL QUOTE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
                    SizedBox(height: 2),
                    Text('Inclusive of all local taxes', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: TransovaTheme.onSurfaceVariant)),
                  ],
                ),
                Text(
                  formatCurrency(_totalQuote),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: TransovaTheme.primary, height: 1.25),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TransovaTheme.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              onPressed: _isProcessingTransaction ? null : _triggerConfirmationWorkflow,
              child: _isProcessingTransaction
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Confirm & Pay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "By confirming, you agree to TRANSOVA's Terms of Logistics & Service Level Agreement.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant, height: 1.42),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 14)),
        Text(formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.w500, color: TransovaTheme.onSurface, fontSize: 14)),
      ],
    );
  }

  Widget _buildInsuranceCardOption({
    required InsuranceOption option,
    required String title,
    required String subtitle,
    required String trailingText,
    required bool isFree,
  }) {
    final bool isSelected = _selectedInsurance == option;
    return InkWell(
      onTap: () => setState(() => _selectedInsurance = option),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? TransovaTheme.surfaceContainerLowest : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? TransovaTheme.primaryContainer : TransovaTheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<InsuranceOption>(
              value: option,
              groupValue: _selectedInsurance,
              activeColor: TransovaTheme.primary,
              onChanged: (InsuranceOption? val) {
                if (val != null) setState(() => _selectedInsurance = val);
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: TransovaTheme.onSurfaceVariant)),
                ],
              ),
            ),
            Text(
              trailingText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isFree ? TransovaTheme.secondary : TransovaTheme.onSurface,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessModalStateOverlay() {
    return Container(
      color: TransovaTheme.surface.withOpacity(0.9),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: TransovaTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TransovaTheme.outlineVariant),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: TransovaTheme.secondaryContainer, shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle, size: 44, color: TransovaTheme.onSecondaryContainer),
                ),
                const SizedBox(height: 24),
                const Text('Booking Confirmed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: TransovaTheme.primary)),
                const SizedBox(height: 8),
                const Text(
                  'Your shipment has been dispatched. Track your delivery in real-time below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: TransovaTheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: TransovaTheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _buildReceiptDetailRow('Order ID', '#TRV-882941-K', isActionText: true),
                      const SizedBox(height: 12),
                      _buildReceiptDetailRow('Carrier Assignment', 'Vantage Logistics Group'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Service Level', style: TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: TransovaTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: const Text('Priority Express', style: TextStyle(color: TransovaTheme.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TransovaTheme.primary,
                          side: const BorderSide(color: TransovaTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {},
                        child: const Text('Download Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TransovaTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ActiveTripScreen()));
                        },
                        child: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptDetailRow(String label, String value, {bool isActionText = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActionText ? FontWeight.w500 : FontWeight.normal,
            color: isActionText ? TransovaTheme.primary : TransovaTheme.onSurface,
          ),
        )
      ],
    );
  }

  Widget _buildMobileBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentMobileNavIndex,
      backgroundColor: TransovaTheme.surfaceContainer,
      indicatorColor: TransovaTheme.secondaryContainer,
      onDestinationSelected: _onNavTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Bookings'),
        NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Fleet'),
        NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Reports'),
      ],
    );
  }
}