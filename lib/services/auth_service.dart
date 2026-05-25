import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  TransovaUser? _currentUser;
  bool _isInitializing = true; // Fixes the 'isInitializing' getter error

  TransovaUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitializing => _isInitializing;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    // Automatically listen to Firebase Auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser == null) {
        _currentUser = null;
      } else {
        // Fetch the REAL role from Firestore instead of just checking email strings
        final role = await _fetchUserRole(firebaseUser);

        _currentUser = TransovaUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? 'guest@transova.com',
          role: role,
          displayName: firebaseUser.displayName ?? (firebaseUser.isAnonymous ? 'Guest User' : 'User'),
        );
      }
      _isInitializing = false; // Initial check complete
      notifyListeners();
    });
  }

  /// Fetches the user role from Firestore.
  /// This ensures Managers and Drivers go to the right pages.
  Future<UserRole> _fetchUserRole(User user) async {
    if (user.isAnonymous) return UserRole.guest;

    try {
      DocumentSnapshot doc = await _db.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        String? roleString = (doc.data() as Map<String, dynamic>)['role'];

        // Match string from Firestore to UserRole Enum
        switch (roleString?.toLowerCase()) {
          case 'admin': return UserRole.admin;
          case 'manager': return UserRole.manager;
          case 'driver': return UserRole.driver;
          case 'customer': return UserRole.customer;
        }
      }
    } catch (e) {
      debugPrint("Error fetching role: $e");
    }

    // Fallback logic for your specific admin emails
    if (user.email == 'admin@gmail.com' || user.email == 'admin@transova.com') {
      return UserRole.admin;
    }

    return UserRole.customer; // Default
  }

  bool hasRole(UserRole requiredRole) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == UserRole.admin) return true;
    if (_currentUser!.role == UserRole.manager && requiredRole != UserRole.admin) return true;
    return _currentUser!.role == requiredRole;
  }

  // Updated Login - The notifyListeners inside _init handles the redirection
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      if (email == 'admin@gmail.com') {
        return await _autoCreateAdmin(email, password);
      }
      debugPrint('Firebase Login Error: ${e.message}');
      return false;
    }
  }

  Future<bool> _autoCreateAdmin(String email, String password) async {
    try {
      debugPrint('Admin account not found. Creating default admin...');
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName('System Admin');
      await _db.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': 'System Admin',
        'role': 'admin',
      });
      return true;
    } catch (e) {
      debugPrint('Auto-create Admin Error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      await _db.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': 'customer',
      });
      return true;
    } catch (e) {
      debugPrint('Firebase Registration Error: $e');
      return false;
    }
  }

  Future<void> continueAsGuest() async => await _auth.signInAnonymously();

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Reset Error: $e');
    }
  }

  Future<void> adminCreateUser(String email, String password, String name, UserRole role) async {
    try {
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempRegistration',
        options: Firebase.app().options,
      );

      UserCredential credential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(name);

      await _db.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role.name, // Saves 'driver', 'manager', etc.
        'createdAt': FieldValue.serverTimestamp(),
      });

      await tempApp.delete();
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }
}