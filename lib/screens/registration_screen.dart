import 'package:flutter/material.dart';
import '../themes/transova_theme.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  final AuthService authService;
  const RegistrationScreen({super.key, required this.authService});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await widget.authService.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        // PERFORMANCE: Clears stack and returns to login route defined in your main.dart
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration failed. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TransovaTheme.background,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TransovaTheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TransovaTheme.spaceLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join Transova Logistics',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TransovaTheme.spaceLg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value?.isEmpty ?? true) ? 'Enter your name' : null,
              ),
              const SizedBox(height: TransovaTheme.spaceMd),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) => (value?.isEmpty ?? true) ? 'Enter your email' : null,
              ),
              const SizedBox(height: TransovaTheme.spaceMd),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) => (value?.length ?? 0) < 6 ? 'Password too short' : null,
              ),
              const SizedBox(height: TransovaTheme.spaceLg),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text('Register'),
              ),
              const SizedBox(height: TransovaTheme.spaceMd),
              const Text(
                'By registering, you will be our "Customer"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: TransovaTheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}