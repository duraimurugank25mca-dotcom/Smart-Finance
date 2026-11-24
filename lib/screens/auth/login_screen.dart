import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/brand_logo.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillCredentials(String email, String pwd) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = pwd;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      if (auth.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.mainShell);
      }
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Logo
                        const BrandLogo(
                          size: 60,
                          title: 'Welcome to SMART FINANCE',
                          subtitle: 'Secure Corporate Financial & Personal Accounting',
                        ),
                        const SizedBox(height: 28),

                        // Email Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDarkNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                              decoration: InputDecoration(
                                hintText: 'name@smartfinance.com',
                                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18, color: AppTheme.textMuted),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.8),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Please enter your email';
                                if (!val.contains('@')) return 'Enter a valid email address';
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDarkNavy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.textMuted),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    size: 18,
                                    color: AppTheme.textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.8),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Please enter your password';
                                return null;
                              },
                            ),
                          ],
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(fontSize: 12, color: AppTheme.primaryPurple, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Sign In Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: auth.isLoading ? null : _handleLogin,
                          child: auth.isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Sign In to Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                        const SizedBox(height: 20),

                        // Quick Demo Login Box (Reference Image 1)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.purpleLightBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.purpleBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUICK DEMO LOGIN:',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: AppTheme.purpleBorder),
                                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _fillCredentials('admin@smartfinance.com', 'Admin@123'),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('👑', style: TextStyle(fontSize: 12)),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'Admin (Full Access)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: AppTheme.purpleBorder),
                                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _fillCredentials('user@smartfinance.com', 'User@123'),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('👤', style: TextStyle(fontSize: 12)),
                                          SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              'User (Personal)',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Register Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                              child: const Text(
                                'Register Now',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryPurple,
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
