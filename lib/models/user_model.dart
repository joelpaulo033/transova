enum UserRole { admin, manager, driver, customer, guest }

class TransovaUser {
  final String id;
  final String email;
  final UserRole role;
  final String displayName;

  TransovaUser({
    required this.id,
    required this.email,
    required this.role,
    required this.displayName,
  });

  // Helper to convert string from Firebase/DB to UserRole
  static UserRole roleFromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'driver':
        return UserRole.driver;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }
}
