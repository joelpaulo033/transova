import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';

class ManagerDashboard extends ConsumerStatefulWidget {
  const ManagerDashboard({super.key});

  @override
  ConsumerState<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<ManagerDashboard> {
  final BookingService _bookingService = BookingService();
  String _selectedFilter = 'All Bookings';
  final List<String> _filters = [
    'All Bookings',
    'Pending',
    'Assigned',
    'In Progress',
    'Completed',
    'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dispatch Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: _bookingService.getAllBookings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                
                final allBookings = snapshot.data ?? [];
                final bookings = allBookings.where((b) {
                  if (_selectedFilter == 'All Bookings') return true;
                  if (_selectedFilter == 'In Progress') {
                    return ['Driver En Route', 'Driver Arrived', 'Trip Started'].contains(b.status);
                  }
                  return b.status == _selectedFilter;
                }).toList();

                if (bookings.isEmpty) {
                  return const Center(child: Text("No bookings found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingCard(booking);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: Colors.black,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) setState(() => _selectedFilter = filter);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    Color statusColor = Colors.grey;
    switch (booking.status) {
      case 'Pending': statusColor = Colors.orange; break;
      case 'Assigned': statusColor = Colors.blue; break;
      case 'Trip Started': statusColor = Colors.purple; break;
      case 'Completed': statusColor = Colors.green; break;
      case 'Cancelled': statusColor = Colors.red; break;
      default: statusColor = Colors.teal; break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ID: ${booking.bookingId.substring(0, 8).toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(booking.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text("${booking.customerName} (${booking.customerPhone})", style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.my_location, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(booking.pickupAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87))),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(booking.destinationAddress, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${booking.distanceKm.toStringAsFixed(1)} km", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  Text(booking.createdAt != null ? DateFormat('MMM dd, yyyy - HH:mm').format(booking.createdAt!) : '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookingDetails(BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _BookingDetailsPanel(booking: booking, bookingService: _bookingService),
      ),
    );
  }
}

class _BookingDetailsPanel extends StatefulWidget {
  final BookingModel booking;
  final BookingService bookingService;

  const _BookingDetailsPanel({required this.booking, required this.bookingService});

  @override
  State<_BookingDetailsPanel> createState() => _BookingDetailsPanelState();
}

class _BookingDetailsPanelState extends State<_BookingDetailsPanel> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 5, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10)))),
          ),
          const SizedBox(height: 24),
          const Text("Booking Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow("Status", widget.booking.status),
          _buildInfoRow("Customer", widget.booking.customerName),
          _buildInfoRow("Phone", widget.booking.customerPhone),
          _buildInfoRow("Vehicle Type", widget.booking.vehicleType),
          _buildInfoRow("Fare Estimate", "TZS ${widget.booking.estimatedFare.toStringAsFixed(0)}"),
          const Divider(height: 32),
          const Text("Locations", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInfoRow("Pickup", widget.booking.pickupAddress),
          _buildInfoRow("Destination", widget.booking.destinationAddress),
          const Divider(height: 32),
          const Text("Driver Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildInfoRow("Assigned Driver", widget.booking.assignedDriverName ?? "Not assigned"),
          if (widget.booking.assignedDriverId != null)
            _buildInfoRow("Driver Phone", widget.booking.assignedDriverPhone ?? "N/A"),
          const SizedBox(height: 32),
          if (widget.booking.status == 'Pending' || widget.booking.status == 'Assigned')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                onPressed: _showDriverAssignmentDialog,
                child: const Text("Assign Driver", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          const SizedBox(height: 12),
          if (widget.booking.status != 'Cancelled' && widget.booking.status != 'Completed')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.all(16)),
                onPressed: () async {
                  await widget.bookingService.updateBookingStatus(widget.booking.bookingId, 'Cancelled');
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Cancel Booking", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showDriverAssignmentDialog() async {
    // Fetch available drivers from users collection
    final driversSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').get();
    final drivers = driversSnapshot.docs.map((doc) => TransovaUser.fromMap(doc.data(), doc.id)).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("Select Driver", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (drivers.isEmpty)
                const Center(child: Text("No drivers found."))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(driver.displayName),
                        subtitle: Text(driver.phoneNumber ?? "No phone"),
                        onTap: () async {
                          Navigator.pop(context); // Close dialog
                          await widget.bookingService.updateBookingStatus(
                            widget.booking.bookingId,
                            'Assigned',
                            driverId: driver.uid,
                            driverName: driver.displayName,
                            driverPhone: driver.phoneNumber ?? "N/A",
                          );
                          if (mounted) Navigator.pop(context); // Close panel
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
}
