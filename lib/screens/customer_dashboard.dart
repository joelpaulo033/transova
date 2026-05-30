import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/booking_model.dart';
import 'dynamic_booking_screen.dart';

// --- PREMIUM COLOR PALETTE ---
const Color kPrimaryBlue = Color(0xFF1565C0);
const Color kSecondaryBlue = Color(0xFF42A5F5);
const Color kAccentTeal = Color(0xFF26A69A);
const Color kBackgroundWhite = Color(0xFFF8FAFC);
const Color kSuccessGreen = Color(0xFF2E7D32);

class CustomerDashboard extends ConsumerStatefulWidget {
  const CustomerDashboard({super.key});

  @override
  ConsumerState<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends ConsumerState<CustomerDashboard> {
  int _selectedIndex = 0;
  final BookingService _bookingService = BookingService();
  late Stream<List<BookingModel>> _customerBookingsStream;
  late Stream<List<Map<String, dynamic>>> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _customerBookingsStream = _bookingService.getCustomerBookings();
    _notificationsStream = _bookingService.getUserNotifications();
  }

  void _showNotificationsDialog(BuildContext context, List<Map<String, dynamic>> notifications) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Notification Center", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              const SizedBox(height: 16),
              Expanded(
                child: notifications.isEmpty
                    ? const Center(child: Text("No notifications yet", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          final isRead = n['read'] == true;
                          return ListTile(
                            leading: Icon(isRead ? Icons.notifications : Icons.notifications_active, color: isRead ? Colors.grey : kPrimaryBlue),
                            title: Text(n['title'] ?? 'Notification', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text(n['message'] ?? ''),
                            onTap: () {
                              if (!isRead) _bookingService.markNotificationAsRead(n['id']);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundWhite,
      appBar: AppBar(
        title: const Text('Transova', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: kPrimaryBlue, fontSize: 24)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final unreadCount = notifications.where((n) => n['read'] == false).length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                    onPressed: () => _showNotificationsDialog(context, notifications),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black87),
            onPressed: () => setState(() => _selectedIndex = 3),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeDashboardView(customerBookingsStream: _customerBookingsStream),
          const ServiceSelectionView(),
          _HistoryView(customerBookingsStream: _customerBookingsStream),
          _CustomerProfileView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: kPrimaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Book'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _HomeDashboardView extends ConsumerWidget {
  final Stream<List<BookingModel>> customerBookingsStream;
  const _HomeDashboardView({required this.customerBookingsStream});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.split(' ').first ?? 'Guest';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust-based Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kPrimaryBlue,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${_getGreeting()}, $displayName 👋", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.verified_user, color: kAccentTeal, size: 16),
                          const SizedBox(width: 4),
                          Text("Verified Customer", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Active Booking Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<List<BookingModel>>(
              stream: customerBookingsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final activeBookings = (snapshot.data ?? []).where((b) => !['Completed', 'Cancelled'].contains(b.status)).toList();

                if (activeBookings.isEmpty) {
                  return _buildEmptyState(context);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Active Rides", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeBookings.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _ActiveBookingCardPremium(booking: activeBookings[index]),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Quick Access", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildActionCard(context, Icons.bookmark, "Saved Locations", Colors.orange, _showSavedLocationsSheet),
                    _buildActionCard(context, Icons.payment, "Payment Methods", Colors.green, (ctx) => _showPaymentMethodsSheet(context, customerBookingsStream)),
                    _buildActionCard(context, Icons.security, "Safety Center", kPrimaryBlue, _showSafetyCenterSheet),
                    _buildActionCard(context, Icons.support_agent, "Support", Colors.purple, _showSupportSheet),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Customer Support", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              const SizedBox(height: 16),
              const ListTile(leading: Icon(Icons.person, color: kPrimaryBlue), title: Text("Manager: Mr. Joel"), subtitle: Text("+255 700 000 000")),
              const ListTile(leading: Icon(Icons.groups, color: kPrimaryBlue), title: Text("Board of Directors"), subtitle: Text("John Doe, Jane Doe")),
              const Divider(),
              const Text("Social Media", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const ListTile(leading: Icon(Icons.camera_alt, color: Colors.purple), title: Text("Instagram"), subtitle: Text("@transova_logistics")),
              const ListTile(leading: Icon(Icons.flutter_dash, color: Colors.blue), title: Text("Twitter / X"), subtitle: Text("@transova")),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentMethodsSheet(BuildContext context, Stream<List<BookingModel>> bookingsStream) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Payment Methods", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              const SizedBox(height: 16),
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(leading: Icon(Icons.account_balance, color: Colors.green), title: Text("CRDB Bank"), subtitle: Text("0150XXXXXXX")),
                      ListTile(leading: Icon(Icons.account_balance, color: Colors.blue), title: Text("NMB Bank"), subtitle: Text("408XXXXXXX")),
                      ListTile(leading: Icon(Icons.phone_android, color: Colors.red), title: Text("M-Pesa"), subtitle: Text("075XXXXXXX")),
                      ListTile(leading: Icon(Icons.phone_android, color: Colors.blue), title: Text("Tigo Pesa"), subtitle: Text("071XXXXXXX")),
                      ListTile(leading: Icon(Icons.phone_android, color: Colors.redAccent), title: Text("Airtel Money"), subtitle: Text("068XXXXXXX")),
                      ListTile(leading: Icon(Icons.phone_android, color: Colors.orange), title: Text("Halopesa"), subtitle: Text("062XXXXXXX")),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Payment Screenshot"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showUploadReceiptDialog(context, bookingsStream);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showUploadReceiptDialog(BuildContext context, Stream<List<BookingModel>> bookingsStream) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Trip to Upload Receipt"),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<BookingModel>>(
              stream: bookingsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final pendingBookings = snapshot.data!.where((b) => b.status == 'Pending' || b.status == 'Assigned').toList();
                if (pendingBookings.isEmpty) return const Center(child: Text("No pending trips found."));

                return ListView.builder(
                  itemCount: pendingBookings.length,
                  itemBuilder: (context, index) {
                    final b = pendingBookings[index];
                    return ListTile(
                      title: Text("${b.destinationAddress} (TZS ${b.estimatedFare.toStringAsFixed(0)})"),
                      subtitle: Text(b.status),
                      onTap: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading receipt...")));
                          try {
                            await BookingService().uploadPaymentReceipt(b.bookingId, File(image.path));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Receipt uploaded! Trip is under payment review.")));
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSafetyCenterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Safety Center", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
              const SizedBox(height: 16),
              ListTile(leading: const Icon(Icons.sos, color: Colors.red, size: 36), title: const Text("Emergency SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), subtitle: const Text("Call 112 immediately"), onTap: (){}),
              ListTile(leading: const Icon(Icons.share_location, color: Colors.blue), title: const Text("Share Live Trip"), subtitle: const Text("Send tracking link to friends/family"), onTap: (){}),
              ListTile(leading: const Icon(Icons.contact_phone, color: Colors.green), title: const Text("Emergency Contacts"), subtitle: const Text("Manage trusted contacts"), onTap: (){}),
              const Divider(),
              const ListTile(leading: Icon(Icons.health_and_safety, color: kPrimaryBlue), title: Text("Safety Guidelines"), subtitle: Text("Always wear your seatbelt. Verify driver details before boarding.")),
            ],
          ),
        );
      },
    );
  }

  void _showSavedLocationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return const SavedLocationsSheet();
      },
    );
  }



  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Icon(Icons.directions_car, size: 64, color: kSecondaryBlue.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Safe Transportation Anytime", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text("Ready to get going? Book a ride with trusted professional drivers.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tap 'Book' below to start.")));
            },
            child: const Text("Book Your First Ride", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, Color color, void Function(BuildContext) onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const Spacer(),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SavedLocationsSheet extends StatefulWidget {
  const SavedLocationsSheet({super.key});

  @override
  State<SavedLocationsSheet> createState() => _SavedLocationsSheetState();
}

class _SavedLocationsSheetState extends State<SavedLocationsSheet> {
  String _home = "";
  String _office = "";
  String _school = "";

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _home = prefs.getString('saved_home') ?? "";
      _office = prefs.getString('saved_office') ?? "";
      _school = prefs.getString('saved_school') ?? "";
    });
  }

  Future<void> _saveLocation(String type, String currentVal) async {
    final TextEditingController controller = TextEditingController(text: currentVal);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set $type Address"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter exact location"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Save")),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_${type.toLowerCase()}', result);
      _loadLocations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Saved Locations", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: const Text("Home"),
              subtitle: Text(_home.isEmpty ? "Add Home Address" : _home),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _saveLocation("Home", _home),
            ),
            ListTile(
              leading: const Icon(Icons.work, color: Colors.orange),
              title: const Text("Office"),
              subtitle: Text(_office.isEmpty ? "Add Office Address" : _office),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _saveLocation("Office", _office),
            ),
            ListTile(
              leading: const Icon(Icons.school, color: Colors.green),
              title: const Text("School"),
              subtitle: Text(_school.isEmpty ? "Add School Address" : _school),
              trailing: const Icon(Icons.edit, size: 20),
              onTap: () => _saveLocation("School", _school),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBookingCardPremium extends StatelessWidget {
  final BookingModel booking;
  const _ActiveBookingCardPremium({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PremiumLiveTrackingScreen(booking: booking))),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text(booking.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Text("TZS ${booking.estimatedFare.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Column(
                      children: const [
                        Icon(Icons.trip_origin, color: kAccentTeal, size: 16),
                        SizedBox(height: 20, width: 2, child: ColoredBox(color: Colors.white38)),
                        Icon(Icons.location_on, color: Colors.white, size: 16),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 18),
                          Text(booking.destinationAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text("${booking.vehicleType} • ${booking.distanceKm.toStringAsFixed(1)} KM", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    const Text("Track Ride", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- LIVE PREMIUM TRACKING SCREEN ---
class PremiumLiveTrackingScreen extends StatelessWidget {
  final BookingModel booking;
  const PremiumLiveTrackingScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundWhite,
      appBar: AppBar(
        title: const Text("Live Tracking", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Colors.redAccent),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency SOS Activated.")));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 3, child: _LiveMapPlaceholder(booking: booking)),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ride Status", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildPremiumTimeline(booking.status),
                    const Divider(height: 40),
                    if (booking.assignedDriverId != null) ...[
                      const Text("Driver Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _DriverInfoCard(booking: booking),
                    ] else ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Finding you the nearest available driver...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTimeline(String status) {
    final steps = ['Pending', 'Assigned', 'Driver En Route', 'Driver Arrived', 'Trip Started', 'Completed'];
    int currentIndex = steps.indexOf(status);
    if (currentIndex == -1) currentIndex = 0; // fallback

    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? kSuccessGreen : Colors.grey.shade300,
                    border: isCurrent ? Border.all(color: kSuccessGreen.withOpacity(0.3), width: 4) : null,
                  ),
                  child: isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                ),
                if (index < steps.length - 1)
                  Container(width: 2, height: 30, color: isCompleted ? kSuccessGreen : Colors.grey.shade300),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(steps[index], style: TextStyle(fontSize: 15, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: isCompleted ? Colors.black87 : Colors.grey)),
            ),
          ],
        );
      }),
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  final BookingModel booking;
  const _DriverInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
        color: kBackgroundWhite,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 25,
                backgroundColor: kPrimaryBlue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(booking.assignedDriverName ?? "Driver", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: kPrimaryBlue, size: 16),
                      ],
                    ),
                    const Text("4.9 ★ • 2,431 trips", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                child: const Text("T 123 ABC", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDriverAction(Icons.call, "Call", kPrimaryBlue, () {}),
              _buildDriverAction(Icons.message, "Message", kSecondaryBlue, () {}),
              _buildDriverAction(Icons.share, "Share", Colors.orange, () {}),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDriverAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LiveMapPlaceholder extends StatefulWidget {
  final BookingModel booking;
  const _LiveMapPlaceholder({required this.booking});

  @override
  State<_LiveMapPlaceholder> createState() => _LiveMapPlaceholderState();
}

class _LiveMapPlaceholderState extends State<_LiveMapPlaceholder> {
  final BookingService _bookingService = BookingService();

  @override
  Widget build(BuildContext context) {
    // Real implementation of Map
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(widget.booking.pickupLatitude, widget.booking.pickupLongitude), zoom: 14),
          markers: {
            Marker(markerId: const MarkerId('pickup'), position: LatLng(widget.booking.pickupLatitude, widget.booking.pickupLongitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)),
            Marker(markerId: const MarkerId('dest'), position: LatLng(widget.booking.destinationLatitude, widget.booking.destinationLongitude), icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
          },
        ),
        if (widget.booking.assignedDriverId != null)
          StreamBuilder<Map<String, dynamic>?>(
            stream: _bookingService.getDriverLocation(widget.booking.assignedDriverId!),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                // We have live GPS coordinates from the driver
                return const Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.gps_fixed, color: kPrimaryBlue),
                          SizedBox(width: 8),
                          Text("GPS Tracking Active", style: TextStyle(fontWeight: FontWeight.bold, color: kSuccessGreen)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          )
      ],
    );
  }
}

// --- HISTORY VIEW ---
class _HistoryView extends StatelessWidget {
  final Stream<List<BookingModel>> customerBookingsStream;
  const _HistoryView({required this.customerBookingsStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: customerBookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final history = (snapshot.data ?? []).where((b) => ['Completed', 'Cancelled'].contains(b.status)).toList();

        if (history.isEmpty) {
          return const Center(child: Text("No past trips found.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final b = history[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: kPrimaryBlue.withOpacity(0.1), child: const Icon(Icons.history, color: kPrimaryBlue)),
                title: Text(b.destinationAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(b.createdAt != null ? DateFormat('MMM dd, yyyy').format(b.createdAt!) : ''),
                trailing: Text("TZS ${b.estimatedFare.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}

// --- PROFILE VIEW ---
class _CustomerProfileView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(radius: 50, backgroundColor: kPrimaryBlue.withOpacity(0.1), child: const Icon(Icons.person, size: 50, color: kPrimaryBlue)),
          const SizedBox(height: 16),
          Text(user?.displayName ?? "Guest", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(leading: const Icon(Icons.security, color: kSuccessGreen), title: const Text("Trusted Profile"), subtitle: const Text("Identity verified"), trailing: const Icon(Icons.check_circle, color: kSuccessGreen), onTap: (){}),
          ListTile(leading: const Icon(Icons.settings), title: const Text("Settings"), trailing: const Icon(Icons.chevron_right), onTap: (){}),
          ListTile(leading: const Icon(Icons.help_outline), title: const Text("Help Center"), trailing: const Icon(Icons.chevron_right), onTap: (){}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Log Out", style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authServiceProvider).logout(),
          ),
        ],
      ),
    );
  }
}

// --- VIEW 2: Premium Service Selection (Idle State) ---
class ServiceSelectionView extends StatelessWidget {
  const ServiceSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Where to next?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5, color: kPrimaryBlue)),
          const SizedBox(height: 32),

          // Premium Image-Based Grid Layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75, // Taller cards for better image display
            children: [
              _buildPremiumCard(context, title: "Wedding", imageUrl: "https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?auto=format&fit=crop&q=80&w=600"),
              _buildPremiumCard(context, title: "Funeral", imageUrl: "https://images.unsplash.com/photo-1632235948332-9ecb5c464c8c?auto=format&fit=crop&q=80&w=600"),
              _buildPremiumCard(context, title: "Convoy", imageUrl: "https://images.unsplash.com/photo-1563720225384-9c0f129fa5a2?auto=format&fit=crop&q=80&w=600"),
              _buildPremiumCard(context, title: "Airport", imageUrl: "https://images.unsplash.com/photo-1538563188159-070c4db2bc65?auto=format&fit=crop&q=80&w=600"),
              _buildPremiumCard(context, title: "Tourism", imageUrl: "https://images.unsplash.com/photo-1516550893923-42d28e5677af?auto=format&fit=crop&q=80&w=600"),
              _buildPremiumCard(context, title: "Corporate", imageUrl: "https://images.unsplash.com/photo-1485291571150-772bcfc10da5?auto=format&fit=crop&q=80&w=600"),
              _buildPremiumCard(context, title: "Cargo", imageUrl: "https://images.unsplash.com/photo-1580674285054-bed31e145f59?auto=format&fit=crop&q=80&w=600"),
              _buildPremiumCard(context, title: "Sanitation", imageUrl: "https://images.unsplash.com/photo-1605810230434-7631ac76ec81?auto=format&fit=crop&q=80&w=600"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, {required String title, required String imageUrl}) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DynamicBookingScreen(initialServiceType: title)
            )
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("Book Now", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.8), size: 10),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
