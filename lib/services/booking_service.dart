import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> createBooking({
    required String customerName,
    required String customerPhone,
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String destinationAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required double distanceKm,
    required double durationMinutes,
    required double estimatedFare,
    required String vehicleType,
    required String paymentMethod,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User must be authenticated to book.");

    final bookingRef = _db.collection('bookings').doc();

    final newBooking = BookingModel(
      bookingId: bookingRef.id,
      customerId: user.uid,
      customerName: customerName,
      customerPhone: customerPhone,
      pickupAddress: pickupAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      destinationAddress: destinationAddress,
      destinationLatitude: destinationLatitude,
      destinationLongitude: destinationLongitude,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      estimatedFare: estimatedFare,
      vehicleType: vehicleType,
      paymentMethod: paymentMethod,
      status: 'Pending',
    );

    await bookingRef.set(newBooking.toMap());

    // Generate notifications
    await _createNotification(
      userId: user.uid,
      title: "Booking Submitted",
      message: "Your booking from $pickupAddress has been successfully submitted.",
    );

    return bookingRef.id;
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus, {String? driverId, String? driverName, String? driverPhone}) async {
    final Map<String, dynamic> updates = {
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newStatus == 'Assigned' && driverId != null) {
      updates['assignedDriverId'] = driverId;
      updates['assignedDriverName'] = driverName;
      updates['assignedDriverPhone'] = driverPhone;
      updates['assignedAt'] = FieldValue.serverTimestamp();
    }

    await _db.collection('bookings').doc(bookingId).update(updates);

    // Retrieve booking to notify customer
    final snapshot = await _db.collection('bookings').doc(bookingId).get();
    if (snapshot.exists) {
      final customerId = snapshot.data()?['customerId'];
      if (customerId != null) {
        String msg = "Your booking status is now $newStatus.";
        if (newStatus == 'Assigned') msg = "Driver $driverName has been assigned.";
        await _createNotification(
          userId: customerId,
          title: "Booking Update",
          message: msg,
        );
      }
    }
  }

  Stream<List<BookingModel>> getCustomerBookings() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('bookings')
        .where('customerId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
          return list;
        });
  }

  Stream<List<BookingModel>> getDriverAssignedBookings() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('bookings')
        .where('assignedDriverId', isEqualTo: user.uid)
        .where('status', whereIn: ['Assigned', 'Driver En Route', 'Driver Arrived', 'Trip Started'])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
          return list;
        });
  }

  Stream<List<BookingModel>> getAllBookings() {
    return _db
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> _createNotification({required String userId, required String title, required String message}) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          list.sort((a, b) {
            final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Future<void> markNotificationAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({'read': true});
  }

  Stream<Map<String, dynamic>?> getDriverLocation(String driverId) {
    return _db.collection('drivers_locations').doc(driverId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  Future<void> uploadPaymentReceipt(String bookingId, File imageFile) async {
    try {
      final String fileName = 'receipts/${DateTime.now().millisecondsSinceEpoch}_$bookingId.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _db.collection('bookings').doc(bookingId).update({
        'paymentReceiptUrl': downloadUrl,
        'status': 'Payment Review',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Notify Manager
      await _db.collection('notifications').add({
        'userId': 'manager', // Assuming a way to notify managers, or just keep it simple
        'title': 'New Payment Receipt',
        'message': 'Booking $bookingId uploaded a payment receipt.',
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception("Failed to upload receipt: $e");
    }
  }
}