enum UserRole {
  admin,
  manager,
  driver,
  customer,
  guest;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'driver':
        return UserRole.driver;
      case 'customer':
        return UserRole.customer;
      default:
        return UserRole.guest;
    }
  }
}

class TransovaUser {
  final String uid;
  final String email;
  final UserRole role;
  final String displayName;
  final String? phoneNumber;
  final String? photoUrl;

  TransovaUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.displayName,
    this.phoneNumber,
    this.photoUrl,
  });

  factory TransovaUser.fromMap(Map<String, dynamic> data, String uid) {
    return TransovaUser(
      uid: uid,
      email: data['email'] ?? '',
      role: UserRole.fromString(data['role']),
      displayName: data['name'] ?? data['displayName'] ?? 'User',
      phoneNumber: data['phoneNumber'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.name,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
    };
  }

  TransovaUser copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
  }) {
    return TransovaUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
