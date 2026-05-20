import 'dart:async';
import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'request_transport_screen.dart';
import 'admin_analytics_screen.dart';
import 'register_vehicle_screen.dart';
import 'service_record_detail_screen.dart';

class RegisterVehicleScreen extends StatefulWidget {
  final AuthService? authService;
  const RegisterVehicleScreen({super.key, this.authService});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedVehicleType = 'Truck';
  String _selectedFuelType = 'Diesel';
  String _selectedComfortLevel = 'Standard';
  String? _selectedDriverId;
  bool _isSubmitting = false;
  bool _submitSuccess = false;
  final int _currentNavIndex = 2;

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;

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
        return; // Already here
      case 3:
        if (user?.role == UserRole.admin) {
          nextScreen = AdminAnalyticsScreen(authService: widget.authService!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin access required')));
          return;
        }
        break;
      default:
        return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;
    final user = widget.authService?.currentUser;

    // SECURITY GUARD: Only Admins or Managers can register vehicles
    final isAuthorized = user != null && (user.role == UserRole.admin || user.role == UserRole.manager);

    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Access Denied: Admin/Manager Only', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Fleet')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TransovaTheme.background,
      appBar: _buildTopAppBar(isDesktop),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: 24,
            horizontal: isDesktop ? 32 : 16,
          ),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Register New Vehicle',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: TransovaTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Onboard a new asset to your logistics network with technical specifications and driver assignment.',
                    style: TextStyle(
                      fontSize: 14,
                      color: TransovaTheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildRegistrationFormCard()),
                        const SizedBox(width: 24),
                        Expanded(flex: 4, child: _buildInsightAndPreviewPanel()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildRegistrationFormCard(),
                        const SizedBox(height: 24),
                        _buildInsightAndPreviewPanel(),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: isDesktop ? null : NavigationBar(
        selectedIndex: _currentNavIndex,
        backgroundColor: TransovaTheme.surfaceContainer,
        indicatorColor: TransovaTheme.secondaryContainer,
        onDestinationSelected: _onNavTap,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.event_note_outlined), label: 'Bookings'),
          const NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Fleet'),
          NavigationDestination(
              icon: Icon(user?.role == UserRole.admin ? Icons.analytics : Icons.person_outline),
              label: user?.role == UserRole.admin ? 'Admin' : 'Account'
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTopAppBar(bool isDesktop) {
    return AppBar(
      backgroundColor: TransovaTheme.surface,
      elevation: 0,
      title: const Text('Asset Onboarding', style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
      leading: isDesktop
          ? IconButton(icon: const Icon(Icons.arrow_back, color: TransovaTheme.primary), onPressed: () => Navigator.pop(context))
          : Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu, color: TransovaTheme.primary), onPressed: () => Scaffold.of(context).openDrawer())),
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
            accountName: Text(user?.displayName ?? 'Guest'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: TransovaTheme.primary)),
          ),
          ListTile(leading: const Icon(Icons.dashboard), title: const Text('Home'), onTap: () => _onNavTap(0)),
          ListTile(leading: const Icon(Icons.local_shipping), title: const Text('Bookings'), onTap: () => _onNavTap(1)),
          ListTile(leading: const Icon(Icons.inventory, color: TransovaTheme.primary), title: const Text('Fleet', style: TextStyle(color: TransovaTheme.primary, fontWeight: FontWeight.bold)), onTap: () => Navigator.pop(context)),
          if (user?.role == UserRole.admin)
            ListTile(leading: const Icon(Icons.analytics), title: const Text('Admin Panel'), onTap: () => _onNavTap(3)),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () => widget.authService?.logout()),
        ],
      ),
    );
  }

  Widget _buildRegistrationFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TransovaTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionStepHeader('1', 'Basic Info'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Plate Number',
                    hint: 'e.g. ABC-1234',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    label: 'Vehicle Type',
                    value: _selectedVehicleType,
                    items: const ['Sedan', 'SUV', 'Van', 'Truck', 'Waste Tanker'],
                    onChanged: (val) => setState(() => _selectedVehicleType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildSectionStepHeader('2', 'Technical Specs'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Capacity (Gallons / Passengers)',
                    hint: 'Enter numerical value',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    label: 'Fuel Type',
                    value: _selectedFuelType,
                    items: const ['Diesel', 'Electric', 'Hybrid', 'Petrol'],
                    onChanged: (val) => setState(() => _selectedFuelType = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Comfort Level',
              style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: ['Standard', 'Premium', 'Luxury'].map((level) {
                return Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: InkWell(
                    onTap: () => setState(() => _selectedComfortLevel = level),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: level,
                          groupValue: _selectedComfortLevel,
                          activeColor: TransovaTheme.primary,
                          onChanged: (val) => setState(() => _selectedComfortLevel = val!),
                        ),
                        Text(level, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            _buildSectionStepHeader('3', 'Driver Assignment'),
            const SizedBox(height: 16),
            const Text(
              'Assign Primary Driver',
              style: TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: TransovaTheme.surfaceContainerLow,
                prefixIcon: const Icon(Icons.search, color: TransovaTheme.outline),
                hintText: 'Search by name or employee ID...',
                hintStyle: const TextStyle(fontSize: 14, color: TransovaTheme.outline),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: TransovaTheme.outlineVariant, width: 2),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: TransovaTheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDriverSelectionCard('MC', 'Marcus Chen', 'driver_marcus')),
                const SizedBox(width: 12),
                Expanded(child: _buildDriverSelectionCard('SJ', 'Sarah Jones', 'driver_sarah')),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _submitSuccess ? Colors.green[600] : TransovaTheme.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isSubmitting ? null : _handleFormSubmit,
                child: _isSubmitting
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('Processing...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_submitSuccess ? Icons.check_circle : Icons.add_task, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _submitSuccess ? 'Success!' : 'Register Vehicle',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightAndPreviewPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TransovaTheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white70, size: 18),
                  SizedBox(width: 8),
                  Text('Registration Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Registered vehicles undergo a 24-hour compliance check. Ensure the plate number matches physical documents to avoid delays in allocation.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recently Registered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(color: TransovaTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 12),
        _buildRecentVehicleCard(Icons.directions_car, 'TRK-8829', 'Mercedes Actros • Truck', 'Pending', TransovaTheme.tertiaryContainer, TransovaTheme.onTertiaryContainer),
        const SizedBox(height: 12),
        _buildRecentVehicleCard(Icons.airport_shuttle, 'VAN-0012', 'Toyota Hiace • Van', 'Active', TransovaTheme.secondaryContainer, TransovaTheme.onSecondaryContainer),
      ],
    );
  }

  Widget _buildSectionStepHeader(String stepNum, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: TransovaTheme.primary, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(stepNum, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
      ],
    );
  }

  Widget _buildTextField({required String label, required String hint, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: TransovaTheme.surfaceContainerLow,
            hintText: hint,
            hintStyle: const TextStyle(color: TransovaTheme.outline, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: TransovaTheme.outlineVariant, width: 2),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: TransovaTheme.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({required String label, required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: TransovaTheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: TransovaTheme.onSurface),
          decoration: const InputDecoration(
            filled: true,
            fillColor: TransovaTheme.surfaceContainerLow,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: TransovaTheme.outlineVariant, width: 2),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: TransovaTheme.primary, width: 2)),
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        ),
      ],
    );
  }

  Widget _buildDriverSelectionCard(String avatarInitials, String name, String driverId) {
    final bool isSelected = _selectedDriverId == driverId;
    return InkWell(
      onTap: () => setState(() => _selectedDriverId = driverId),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? TransovaTheme.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? TransovaTheme.primary : TransovaTheme.outlineVariant),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: TransovaTheme.surfaceContainerHigh, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(avatarInitials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: TransovaTheme.primary)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    const Text('AVAILABLE', style: TextStyle(fontSize: 10, color: TransovaTheme.onSurfaceVariant, letterSpacing: 0.5)),
                  ],
                )
              ],
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.check_circle_outline,
              color: isSelected ? TransovaTheme.primary : TransovaTheme.outline,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecentVehicleCard(IconData icon, String identifier, String specs, String badgeText, Color badgeBg, Color badgeTextCol) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TransovaTheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: TransovaTheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 30, color: TransovaTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(identifier, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(99)),
                      child: Text(badgeText, style: TextStyle(fontSize: 11, color: badgeTextCol, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                Text(specs, style: const TextStyle(fontSize: 14, color: TransovaTheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: TransovaTheme.outline),
                    SizedBox(width: 4),
                    Text('Added recently', style: TextStyle(fontSize: 11, color: TransovaTheme.outline)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _handleFormSubmit() {
    setState(() {
      _isSubmitting = true;
    });

    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitSuccess = true;
        });

        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _submitSuccess = false;
              _selectedDriverId = null;
              _formKey.currentState?.reset();
            });
            Navigator.pop(context);
          }
        });
      }
    });
  }
}