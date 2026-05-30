import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String destinationAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final double distanceKm;
  final double durationMinutes;
  final double estimatedFare;
  final String vehicleType;
  final String paymentMethod;
  final String status;
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final String? vehicleRegistrationNumber;
  final String? driverRating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? assignedAt;

  BookingModel({
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.destinationAddress,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedFare,
    required this.vehicleType,
    required this.paymentMethod,
    required this.status,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedDriverPhone,
    this.vehicleRegistrationNumber,
    this.driverRating,
    this.createdAt,
    this.updatedAt,
    this.assignedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      bookingId: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      pickupLatitude: (map['pickupLatitude'] ?? 0.0).toDouble(),
      pickupLongitude: (map['pickupLongitude'] ?? 0.0).toDouble(),
      destinationAddress: map['destinationAddress'] ?? '',
      destinationLatitude: (map['destinationLatitude'] ?? 0.0).toDouble(),
      destinationLongitude: (map['destinationLongitude'] ?? 0.0).toDouble(),
      distanceKm: (map['distanceKm'] ?? 0.0).toDouble(),
      durationMinutes: (map['durationMinutes'] ?? 0.0).toDouble(),
      estimatedFare: (map['estimatedFare'] ?? 0.0).toDouble(),
      vehicleType: map['vehicleType'] ?? 'standard',
      paymentMethod: map['paymentMethod'] ?? 'cash',
      status: map['status'] ?? 'Pending',
      assignedDriverId: map['assignedDriverId'],
      assignedDriverName: map['assignedDriverName'],
      assignedDriverPhone: map['assignedDriverPhone'],
      vehicleRegistrationNumber: map['vehicleRegistrationNumber'],
      driverRating: map['driverRating']?.toString(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupAddress': pickupAddress,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'destinationAddress': destinationAddress,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'estimatedFare': estimatedFare,
      'vehicleType': vehicleType,
      'paymentMethod': paymentMethod,
      'status': status,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedDriverPhone': assignedDriverPhone,
      'vehicleRegistrationNumber': vehicleRegistrationNumber,
      'driverRating': driverRating,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
    };
  }
}