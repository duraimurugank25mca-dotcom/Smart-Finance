import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppTheme.expenseRedDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2E0854), // Deep royal violet (Reference Image 1)
              Color(0xFF4A1584), // Rich purple mid-tone
              Color(0xFF6D28D9), // Vibrant electric purple
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.22),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const BrandLogo(
                          size: 54,
                          title: 'Create Smart Finance Account',
                          subtitle: 'Track income, manage expenses & control spending',
                        ),
                        const SizedBox(height: 24),

                        // Full Name
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: AppTheme.textSecondary),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 14),

                        // Email Address
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.textSecondary),
                          ),
                          validator: (val) => val == null || !val.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 14),

                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                          decoration: InputDecoration(
                            labelText: 'Password (min. 6 characters)',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppTheme.textSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
                          child: auth.isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Create Account'),
                        ),
                        const SizedBox(height: 18),

                        // Sign In Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppTheme.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
