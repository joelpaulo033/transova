// lib/screens/customer_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import '../themes/transova_theme.dart';
import 'dynamic_booking_screen.dart'; // Ensure this contains the constructor accepting initialServiceType

// --- PRODUCTION STATE PROVIDER ---
// Listens to Firebase Realtime Database to determine if a trip is active
final activeBookingProvider = StreamProvider<bool>((ref) {
  return FirebaseDatabase.instance.ref('bookings/active').onValue.map((event) {
    return event.snapshot.exists;
  });
});

// --- MAIN DASHBOARD ---
class CustomerDashboard extends ConsumerWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBookingAsync = ref.watch(activeBookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            'Transova',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5)
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authServiceProvider).logout(),
          ),
        ],
      ),
      // Reactive UI: Switches between Event Selection and Live Tracking automatically
      body: activeBookingAsync.when(
        data: (isActive) => isActive ? const TrackingView() : const ServiceSelectionView(),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.black)),
        error: (err, stack) => const Center(child: Text("Connection error. Please check your network.")),
      ),
    );
  }
}

// --- VIEW 1: Reactive Tracking View (Active Order) ---
class TrackingView extends ConsumerStatefulWidget {
  const TrackingView({super.key});

  @override
  ConsumerState<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends ConsumerState<TrackingView> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final telemetryRef = FirebaseDatabase.instance.ref('telemetry/active_vehicle');

    return Stack(
      children: [
        StreamBuilder(
          stream: telemetryRef.onValue,
          builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
            // Default location: Dar es Salaam Base
            LatLng pos = const LatLng(-6.816064, 39.280335);

            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
              pos = LatLng(data['lat'], data['lng']);

              // Smoothly animate the camera as the vehicle moves
              _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
            }

            return GoogleMap(
              onMapCreated: (c) => _mapController = c,
              initialCameraPosition: CameraPosition(target: pos, zoom: 17),
              markers: {
                Marker(
                  markerId: const MarkerId('vehicle'),
                  position: pos,
                )
              },
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              mapType: MapType.normal,
            );
          },
        ),

        // Professional Overlay Status Card
        Positioned(
          top: 20, left: 20, right: 20,
          child: Card(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Icon(Icons.local_shipping, color: Colors.black, size: 28),
              title: Text("Fleet Dispatched", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text("Your vehicles are arriving shortly.", style: TextStyle(color: Colors.grey)),
            ),
          ),
        )
      ],
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
          Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.grey[600], letterSpacing: 0.5)),
          const SizedBox(height: 8),
          const Text("Where to next?", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.2, letterSpacing: -0.5)),
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
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.directions_car, color: Colors.white54, size: 40),
                ),
              ),

              // 2. Cinematic Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // 3. Text and Animated Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        )
                    ),
                    const SizedBox(height: 12),
                    const _TwinklingBookNowButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CUSTOM ANIMATED BUTTON WIDGET ---
class _TwinklingBookNowButton extends StatefulWidget {
  const _TwinklingBookNowButton();

  @override
  State<_TwinklingBookNowButton> createState() => _TwinklingBookNowButtonState();
}

class _TwinklingBookNowButtonState extends State<_TwinklingBookNowButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Creates a continuous looping animation that pulses every 1.5 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "Book Now",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                )
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios, size: 10, color: Colors.black),
          ],
        ),
      ),
    );
  }
}