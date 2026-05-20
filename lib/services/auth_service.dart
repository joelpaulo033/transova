import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  TransovaUser? _currentUser;

  TransovaUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // Automatically listen to Firebase Auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser == null) {
        _currentUser = null;
      } else {
        _currentUser = TransovaUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? 'guest@transova.com',
          role: _determineRole(firebaseUser.email),
          displayName: firebaseUser.displayName ?? (firebaseUser.isAnonymous ? 'Guest User' : 'User'),
        );
      }
      notifyListeners();
    });
  }

  bool hasRole(UserRole requiredRole) {
    if (_currentUser == null) return false;

    // Logic: Admins can see everything
    if (_currentUser!.role == UserRole.admin) return true;

    // Managers can see everything except Admin-only stuff
    if (_currentUser!.role == UserRole.manager && requiredRole != UserRole.admin) return true;

    // Exact match for drivers or others
    return _currentUser!.role == requiredRole;
  }

  // Updated to recognize admin@gmail.com as the System Admin
  UserRole _determineRole(String? email) {
    if (email == null || email.isEmpty || email == 'guest@transova.com') {
      return UserRole.guest;
    }
    // Added admin@gmail.com to the admin check
    if (email == 'admin@gmail.com' || email == 'admin@transova.com') return UserRole.admin;
    if (email == 'manager@transova.com') return UserRole.manager;
    if (email == 'driver@transova.com') return UserRole.driver;

    return UserRole.customer; // Default role
  }

  // Real Firebase login function with Auto-Create Admin logic
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      // If logging in as admin fails (likely because the account doesn't exist yet),
      // we intercept the error and silently create the admin account on the fly.
      if (email == 'admin@gmail.com') {
        try {
          debugPrint('Admin account not found. Creating default admin...');
          UserCredential credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password, // Remember to use at least 6 characters (e.g., admin123)
          );

          await credential.user?.updateDisplayName('System Admin');
          await credential.user?.reload();

          // Add admin to Firestore so they show up in user management
          await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
            'email': email,
            'name': 'System Admin',
            'role': 'admin',
          });

          return true; // Successfully created and logged in
        } catch (createError) {
          debugPrint('Auto-create Admin Error: $createError');
          return false;
        }
      }

      debugPrint('Firebase Login Error: ${e.message}');
      return false;
    }
  }

  // Register function - defaults to Customer
  Future<bool> register(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      // Save customer to Firestore
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': 'customer',
      });

      await credential.user?.reload();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Registration Error: ${e.message}');
      return false;
    }
  }

  // Guest Mode using Firebase Anonymous Authentication
  Future<void> continueAsGuest() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('Firebase Guest Login Error: $e');
    }
  }

  // Real Firebase Sign Out
  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent to $email');
    } catch (e) {
      debugPrint('Firebase Reset Password Error: $e');
    }
  }

  // FIXED: Corrected parameters to match UI and implemented Firestore save
  Future<void> adminCreateUser(String email, String password, String name, UserRole role) async {
    try {
      // 1. Create a secondary Firebase App.
      // If we use the primary instance, Firebase will log the Admin out!
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempRegistration',
        options: Firebase.app().options,
      );

      // 2. Register the user on the secondary app
      UserCredential credential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(name);

      // 3. Save their data to Firestore so your Admin Panel list can see them
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role.name, // Saves 'driver', 'manager', or 'customer'
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Delete the temporary app instance so it doesn't cause memory leaks
      await tempApp.delete();

      debugPrint('Successfully created user: $name ($email) as ${role.name}');
    } catch (e) {
      debugPrint('Admin Create User Error: $e');
      throw Exception('Failed to create user: $e');
    }
  }
}