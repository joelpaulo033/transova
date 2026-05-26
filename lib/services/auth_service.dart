import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProvider = FutureProvider<TransovaUser?>((ref) async {
  final user = await ref.watch(authStateProvider.future);

  if (user == null) return null;

  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      return TransovaUser.fromMap(doc.data()!, user.uid);
    }
  } catch (e) {
    // SILENT HANDLING: If we don't have permission to read the doc yet,
    // don't crash the app and don't show an error to the user.
    if (e.toString().contains('permission-denied')) {
      print("Firestore access denied for user: ${user.uid}. Ignoring.");
      return null;
    }
    print("Error fetching user data from Firestore: $e");
  }

  // Default fallback for authenticated users not yet in Firestore
  return TransovaUser(
    uid: user.uid,
    email: user.email ?? '',
    role: UserRole.customer,
    displayName: user.displayName ?? 'User',
  );
});

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<void> login(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> logout() => _auth.signOut();

  Future<void> register(String email, String password, String name) async {
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);

    await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'name': name,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

// services/auth_service.dart

  Future<void> resetPassword(String email) async {
    try {
      // DON'T query Firestore here.
      // Just call Firebase Auth directly.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      // Handle specific errors like 'user-not-found'
      throw Exception(e.message ?? 'An error occurred');
    }
  }
}