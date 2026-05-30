// Location: lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true; // Toggles between Login and Register modes
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Strict Password Validator
  bool _isPasswordStrong(String password) {
    // Requires at least 6 chars, 1 uppercase, 1 lowercase, and 1 number
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d\w\W]{6,}$');
    return regex.hasMatch(password);
  }

  void _submitForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    // 1. Basic empty field validation
    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }

    // 2. Registration specific validation
    if (!_isLogin) {
      if (firstName.isEmpty || lastName.isEmpty) {
        _showError('Please provide both your First and Last name.');
        return;
      }
      if (password != confirmPassword) {
        _showError('Passwords do not match.');
        return;
      }
      if (!_isPasswordStrong(password)) {
        _showError(
          'Password must be at least 6 characters and contain an uppercase letter, a lowercase letter, and a number.',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        await authService.login(email, password);
      } else {
        // Combine names for the auth service
        final fullName = "$firstName $lastName";
        await authService.register(email, password, fullName);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address to reset your password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'If an account exists for this email, a reset link has been sent.',
            ),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorText = e.toString().replaceFirst('Exception: ', '');
        _showError(errorText);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen width for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.grey[200], // Outer background color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ), // Max width for the split card
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: isDesktop
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Side - Information Panel
                        Expanded(flex: 4, child: _buildInfoPanel()),
                        // Right Side - Form Panel
                        Expanded(flex: 5, child: _buildFormPanel()),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // On mobile, stack info on top of form
                      _buildInfoPanel(),
                      _buildFormPanel(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // UI WIDGET: INFORMATION PANEL (Left Side)
  // =========================================================================
  Widget _buildInfoPanel() {
    return Container(
      color:
          Colors.grey[100], // Slightly darker background to separate from form
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping,
                size: 32,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 12),
              Text(
                'TRANSOVA LOGISTICS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'SECURE ACCESS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _isLogin ? 'Welcome Back' : 'Join Transova',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isLogin
                ? 'Sign in to continue with secure access to transport and fleet management services.'
                : 'Create an account to request vehicles, manage cargo, and access logistics tools.',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 40),
          const Text(
            'How to use this system',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildBulletPoint(
            'Use your registered email address and secure password.',
          ),
          _buildBulletPoint(
            'Keep your account active with role-based protected sessions.',
          ),
          _buildBulletPoint('Reset your password quickly if you lose access.'),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 20, color: Colors.grey)),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // UI WIDGET: FORM PANEL (Right Side)
  // =========================================================================
  Widget _buildFormPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.login, size: 32),
              const SizedBox(width: 12),
              Text(
                _isLogin ? 'Login' : 'Register',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your credentials to access your account.',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),

          // First Name & Last Name (Only in Register Mode)
          if (!_isLogin) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(Icons.person, 'John'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration(
                          Icons.person_outline,
                          'Doe',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          const Text(
            'Email Address',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration(
              Icons.email_outlined,
              'you@example.com',
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Password',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: _inputDecoration(
              Icons.lock_outline,
              '••••••••',
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Confirm Password (Only in Register Mode)
          if (!_isLogin) ...[
            const Text(
              'Confirm Password',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              decoration: _inputDecoration(
                Icons.lock_reset,
                '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _passwordController.clear();
                    _confirmPasswordController.clear();
                    if (!_isLogin) {
                      _firstNameController.clear();
                      _lastNameController.clear();
                    }
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  _isLogin
                      ? "Don't have an account? Apply now!"
                      : "Already have an account? Login",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_isLogin)
                TextButton(
                  onPressed: _isLoading ? null : _handleForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    alignment: Alignment.centerRight,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitForm,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _isLogin ? Icons.login : Icons.person_add,
                      color: Colors.white,
                    ),
              label: Text(
                _isLogin ? 'Login' : 'Register',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, // Dark button like the photo
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable text field decoration
  InputDecoration _inputDecoration(
    IconData icon,
    String hint, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
