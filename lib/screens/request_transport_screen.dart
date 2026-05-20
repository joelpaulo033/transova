import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'fleet_maintenance_screen.dart';
import 'admin_analytics_screen.dart';
import 'booking_quote_confirmation_screen.dart';

class RequestTransportScreen extends StatefulWidget {
  final AuthService? authService;
  const RequestTransportScreen({super.key, this.authService});

  @override
  State<RequestTransportScreen> createState() => _RequestTransportScreenState();
}

class _RequestTransportScreenState extends State<RequestTransportScreen> {
  int _currentStep = 1;
  final int _totalSteps = 3;
  int _currentMobileNavIndex = 1;

  final _pickupController = TextEditingController();
  final _deliveryController = TextEditingController();
  String _selectedCargoType = 'Dry Freight';
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _pickupDateController = TextEditingController();
  String _selectedPickupWindow = 'Morning (08:00 - 12:00)';

  int _selectedCargoIndex = 0;

  // Helper for TZS conversion: $1 USD = 2600 TZS
  String formatCurrency(double usdAmount) {
    double tzsAmount = usdAmount * 2600;
    return 'TZS ${tzsAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}';
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _deliveryController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _pickupDateController.dispose();
    super.dispose();
  }

  void _handleNextStep() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BookingQuoteConfirmationScreen(authService: widget.authService)),
      );
    }
  }

  void _handlePrevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
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
        return; // Already here
      case 2:
        nextScreen = const FleetMaintenanceScreen();
        break;
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService?.currentUser;
    final isAuthorized = user != null && user.role != UserRole.guest;

    // SECURITY GUARD: Guest users cannot access booking workflows
    if (!isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: TransovaTheme.error),
              const SizedBox(height: 16),
              const Text('Account Required to Request Transport', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back to Dashboard')),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          backgroundColor: TransovaTheme.background,
          appBar: _buildAdaptiveHeader(isDesktop),
          bottomNavigationBar: isDesktop ? null : _buildMobileBottomNavigationBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressStepper(),
                      const SizedBox(height: 32),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 8, child: _buildFormWorkflow()),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: _buildSidebarSummary()),
                          ],
                        )
                      else ...[
                        _buildFormWorkflow(),
                        const SizedBox(height: 24),
                        _buildSidebarSummary(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
        icon: const Icon(Icons.arrow_back, color: TransovaTheme.primary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          const Text(
            'TRANSOVA',
            style: TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.primary, letterSpacing: 0.5),
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
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
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 20,
              right: 20,
              child: Container(height: 2, color: TransovaTheme.surfaceVariant),
            ),
            Positioned(
              left: 20,
              right: 20,
              child: AnimatedAlign(
                alignment: _currentStep == 1
                    ? Alignment.centerLeft
                    : (_currentStep == 2 ? Alignment.center : Alignment.centerRight),
                duration: const Duration(milliseconds: 400),
                child: FractionallySizedBox(
                  widthFactor: _currentStep == 1 ? 0.0 : (_currentStep == 2 ? 0.5 : 1.0),
                  child: Container(height: 2, color: TransovaTheme.primary),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepNode(1, 'Route'),
                _buildStepNode(2, 'Cargo'),
                _buildStepNode(3, 'Schedule'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNode(int stepIndex, String title) {
    bool isActive = stepIndex == _currentStep;
    bool isCompleted = stepIndex < _currentStep;

    Color nodeColor = TransovaTheme.surfaceVariant;
    Widget nodeContent = Text('$stepIndex', style: const TextStyle(fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant));

    if (isActive) {
      nodeColor = TransovaTheme.primary;
      nodeContent = Text('$stepIndex', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white));
    } else if (isCompleted) {
      nodeColor = TransovaTheme.secondary;
      nodeContent = const Icon(Icons.check, size: 18, color: Colors.white);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: nodeColor,
            shape: BoxShape.circle,
            border: Border.all(color: TransovaTheme.background, width: 4),
          ),
          child: Center(child: nodeContent),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive || isCompleted ? TransovaTheme.primary : TransovaTheme.onSurfaceVariant,
          ),
        )
      ],
    );
  }

  Widget _buildFormWorkflow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildActiveStepFormBlock(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentStep > 1)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: TransovaTheme.primary,
                  side: const BorderSide(color: TransovaTheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                onPressed: _handlePrevStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              const SizedBox.shrink(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == _totalSteps ? TransovaTheme.secondary : TransovaTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 2,
              ),
              onPressed: _handleNextStep,
              icon: Icon(_currentStep == _totalSteps ? Icons.rocket_launch : Icons.arrow_forward),
              label: Text(
                _currentStep == _totalSteps ? 'Submit Request' : 'Next Step',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildActiveStepFormBlock() {
    switch (_currentStep) {
      case 1:
        return _buildStep1RouteDetails();
      case 2:
        return _buildStep2CargoDetails();
      case 3:
        return _buildStep3Scheduling();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1RouteDetails() {
    return Column(
      key: const ValueKey(1),
      children: [
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
                'Route Information',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: TransovaTheme.primary),
              ),
              const SizedBox(height: 16),
              _buildUnderlinedInputField(
                label: 'Pickup Location',
                icon: Icons.location_on,
                iconColor: TransovaTheme.primary,
                hintText: 'Enter origin city or terminal',
                controller: _pickupController,
              ),
              const SizedBox(height: 16),
              _buildUnderlinedInputField(
                label: 'Delivery Location',
                icon: Icons.local_shipping,
                iconColor: TransovaTheme.secondary,
                hintText: 'Enter destination city or terminal',
                controller: _deliveryController,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            color: TransovaTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCCT4SNPndD6HnjD7UCtu9mR5a8984Yteh5SGAXLfSM20VRtBQstqTtQy_eaPnba4mj4cCaP6U8_s-SZUKawrqkBe_6A1Wn1yPEZaCR8CERO_iGSWMU4vgm0ZW-jbDKI0WuYzal6NL4lXZVSTN3c8G2iv52lJ9ZjInD9pPCxpox0qUkAy2lYmraSo_rzSJRaMkRCoPeDEe79THRceAnJ1Ij6t_eTik2CVqX8x4TQb-HNL5mzT_bJwY4ORzSH_C_MILb1vgIyf53aJc-'),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.map, color: TransovaTheme.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Estimated distance: 482 km',
                        style: TextStyle(fontWeight: FontWeight.w500, color: TransovaTheme.onSurface, fontSize: 14),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStep2CargoDetails() {
    return Column(
      key: const ValueKey(2),
      children: [
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
                'Cargo Specifications',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: TransovaTheme.primary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectionDropdown(
                      label: 'Cargo Type',
                      value: _selectedCargoType,
                      items: ['Dry Freight', 'Refrigerated', 'Hazardous Materials', 'Oversized Load'],
                      onChanged: (val) => setState(() => _selectedCargoType = val!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBoxInputField(
                      label: 'Weight (kg)',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      controller: _weightController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Dimensions (L x W x H in cm)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildBoxInputField(label: '', hint: 'Length', keyboardType: TextInputType.number, controller: _lengthController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBoxInputField(label: '', hint: 'Width', keyboardType: TextInputType.number, controller: _widthController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBoxInputField(label: '', hint: 'Height', keyboardType: TextInputType.number, controller: _heightController)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(builder: (context, constraints) {
          final items = [
            {'icon': Icons.inventory_2, 'label': 'Standard Pallet'},
            {'icon': Icons.all_inbox, 'label': 'Crated Goods'},
            {'icon': Icons.ac_unit, 'label': 'Cold Chain'},
            {'icon': Icons.warning, 'label': 'HAZMAT'},
          ];

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: 4,
            itemBuilder: (context, idx) {
              final isSelected = _selectedCargoIndex == idx;
              return InkWell(
                onTap: () => setState(() => _selectedCargoIndex = idx),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? TransovaTheme.surfaceContainerHigh : TransovaTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? TransovaTheme.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[idx]['icon'] as IconData, size: 36, color: TransovaTheme.primary),
                      const SizedBox(height: 8),
                      Text(items[idx]['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))
                    ],
                  ),
                ),
              );
            },
          );
        })
      ],
    );
  }

  Widget _buildStep3Scheduling() {
    return Column(
      key: const ValueKey(3),
      children: [
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
                'Scheduling',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: TransovaTheme.primary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildBoxInputField(
                      label: 'Pickup Date',
                      hint: 'YYYY-MM-DD',
                      controller: _pickupDateController,
                      suffixIcon: const Icon(Icons.calendar_today, size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSelectionDropdown(
                      label: 'Pickup Window',
                      value: _selectedPickupWindow,
                      items: const ['Morning (08:00 - 12:00)', 'Afternoon (12:00 - 17:00)', 'Evening (17:00 - 21:00)', 'Strict Appt Time'],
                      onChanged: (val) => setState(() => _selectedPickupWindow = val!),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TransovaTheme.secondaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TransovaTheme.secondary.withOpacity(0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info, color: TransovaTheme.secondary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choosing a flexible window can reduce your transport costs by up to 15% through route optimization.',
                        style: TextStyle(fontSize: 14, color: TransovaTheme.onSecondaryContainer, height: 1.42),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TransovaTheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Express Delivery Available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('Get it there 24 hours faster for a flat premium.', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: TransovaTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                ),
                onPressed: () {},
                child: const Text('Add Express', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildUnderlinedInputField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          color: TransovaTheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: TransovaTheme.outline, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              )
            ],
          ),
        ),
        Container(height: 2, color: TransovaTheme.outlineVariant),
      ],
    );
  }

  Widget _buildBoxInputField({
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required TextEditingController controller,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
          const SizedBox(height: 4),
        ],
        Container(
          decoration: const BoxDecoration(
            color: TransovaTheme.surfaceContainerLow,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            border: Border(bottom: BorderSide(color: TransovaTheme.outlineVariant, width: 2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: TransovaTheme.outline, fontSize: 14),
              border: InputBorder.none,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: TransovaTheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: const BoxDecoration(
            color: TransovaTheme.surfaceContainerLow,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            border: Border(bottom: BorderSide(color: TransovaTheme.outlineVariant, width: 2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarSummary() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: TransovaTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: TransovaTheme.primary)),
              const SizedBox(height: 16),
              _buildSummaryRow('Service Type:', 'Standard LTL'),
              const SizedBox(height: 12),
              _buildSummaryRow('Est. Transit:', '2-3 Business Days'),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: TransovaTheme.outlineVariant),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Estimated Quote:', style: TextStyle(fontSize: 11, color: Color(0xFF616161))),
                  Text(formatCurrency(1240.00), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: TransovaTheme.primary)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TransovaTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TransovaTheme.outlineVariant),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user, color: TransovaTheme.primary),
                  SizedBox(width: 8),
                  Text('Transova Guarantee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: TransovaTheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'All shipments include basic insurance and real-time GPS tracking as standard.',
                style: TextStyle(fontSize: 14, color: TransovaTheme.onSurfaceVariant, height: 1.42),
              ),
              const SizedBox(height: 16),
              Container(
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuD_RB_9bwD8s5I2oR_JptyeAYBVhPYi8fmp1glOVAs3WnskPnBgaQRgH5KjcuwVeQ39zpNDHLB0QH5XubhFjImd0-vCrt613vdCGAGVkOiEnQbrh4FGWVFwuyBPc6J-G55-_VtIMd6NQLVjYf6G3P3rP8SWxCicX4mmU29E61rdRUWzvQv9wETgj99Q5hiPONQfzPc3yAE--xxwlXuUuGAPAiBezggrkAtFZxClRReebhjwZDvB6xAwdOJtzbb2xDTKf62-sRYssLMk'),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TransovaTheme.onSurfaceVariant, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: TransovaTheme.onSurface, fontSize: 14)),
      ],
    );
  }

  Widget _buildMobileBottomNavigationBar() {
    final user = widget.authService?.currentUser;
    return NavigationBar(
      selectedIndex: _currentMobileNavIndex,
      backgroundColor: TransovaTheme.surfaceContainer,
      indicatorColor: TransovaTheme.secondaryContainer,
      onDestinationSelected: _onNavTap,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Bookings'),
        const NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Fleet'),
        NavigationDestination(
            icon: Icon(user?.role == UserRole.admin ? Icons.analytics : Icons.person_outline),
            label: user?.role == UserRole.admin ? 'Admin' : 'Account'
        ),
      ],
    );
  }
}