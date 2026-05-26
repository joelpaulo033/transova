import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pricing_engine.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveBookingToFirestore({
    required ServiceCategory serviceType,
    required VehicleCapacity vehicleCapacity,
    required PricingBreakdown breakdown,
    required String pickupAddress,
    required String destinationAddress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User must be authenticated to book.");

    try {
      await _db.collection('bookings').add({
        'customerId': user.uid,
        'serviceType': serviceType.name,
        'vehicleType': vehicleCapacity.name,
        'pickupLocation': pickupAddress,
        'destination': destinationAddress,
        'distanceKm': breakdown.distanceKm,
        'weightKg': breakdown.weightKg,
        'pricePerKm': breakdown.baseRate,
        'totalPrice': breakdown.totalPrice,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to save booking: $e");
    }
  }
}