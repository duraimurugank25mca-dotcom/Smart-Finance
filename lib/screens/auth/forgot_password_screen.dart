import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../routes/app_routes.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                constraints: const BoxConstraints(maxWidth: 440),
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
                  child: _submitted
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppTheme.incomeGreenBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, size: 52, color: AppTheme.incomeGreen),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Reset Link Dispatched!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDarkNavy,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'If an account exists for ${_emailController.text}, password reset instructions have been dispatched.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                              child: const Text('Return to Sign In'),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const BrandLogo(
                              size: 54,
                              title: 'Reset Password',
                              subtitle: 'Enter registered email to recover your access',
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                              decoration: const InputDecoration(
                                hintText: 'name@smartfinance.com',
                                prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppTheme.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 24),

                            ElevatedButton(
                              onPressed: () {
                                if (_emailController.text.contains('@')) {
                                  setState(() => _submitted = true);
                                }
                              },
                              child: const Text('Send Reset Link'),
                            ),
                            const SizedBox(height: 16),

                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Back to Sign In',
                                style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
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
