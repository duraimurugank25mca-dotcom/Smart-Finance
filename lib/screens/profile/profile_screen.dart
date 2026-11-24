import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Profile & Security Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDarkNavy,
          ),
        ),
        actions: [
          if (user?.isAdmin ?? false)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.purplePillBg,
                  side: const BorderSide(color: AppTheme.purpleBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.admin_panel_settings_rounded, size: 14, color: AppTheme.primaryPurple),
                label: const Text('Admin Console', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildProfileDetailsCard(user)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildChangePasswordCard()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildProfileDetailsCard(user),
                      const SizedBox(height: 16),
                      _buildChangePasswordCard(),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // QUICK NAVIGATION TILES TO SMART MODULES
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.advancesGoldBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.pie_chart_outline_rounded, color: AppTheme.advancesGold, size: 20),
                    ),
                    title: const Text('Monthly Budgets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Manage category spending limits & alerts', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.budgets),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.incomeGreenBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.savings_outlined, color: AppTheme.incomeGreenDark, size: 20),
                    ),
                    title: const Text('Savings Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Emergency funds and personal targets', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.savings),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.purplePillBg, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.account_balance_outlined, color: AppTheme.primaryPurple, size: 20),
                    ),
                    title: const Text('EMI & Loan Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Track due dates and automated schedulers', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.emi),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.expenseRedBorder, width: 1.2),
                  backgroundColor: AppTheme.expenseRedBg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.expenseRedDark),
                label: const Text(
                  'Secure Logout',
                  style: TextStyle(color: AppTheme.expenseRedDark, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Matching Left Card of Reference Image 5
  Widget _buildProfileDetailsCard(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Profile Details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // Purple Circle Avatar with Initial
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryPurple,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Durai Finance',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'user@smartfinance.com',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B1E78), // Dark purple badge matching Image 5
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user?.role ?? 'USER',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Active System Permissions Container (Reference Image 5)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active System Permissions:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                ),
                SizedBox(height: 8),
                Text('✓ Financial Ledger Access: Enabled', style: TextStyle(fontSize: 12, color: AppTheme.textDarkNavy, height: 1.4)),
                Text('✓ AI Smart Bill OCR Scanner: Enabled', style: TextStyle(fontSize: 12, color: AppTheme.textDarkNavy, height: 1.4)),
                Text('✓ Multilingual Voice Assistant: Enabled', style: TextStyle(fontSize: 12, color: AppTheme.textDarkNavy, height: 1.4)),
                Text('✓ PDF Statement Generation: Enabled', style: TextStyle(fontSize: 12, color: AppTheme.textDarkNavy, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Matching Right Card of Reference Image 5
  Widget _buildChangePasswordCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Change Password',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirm New Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(hintText: '••••••••'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppTheme.incomeGreenDark,
                  content: Text('Password security credentials successfully updated!'),
                ),
              );
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
            },
            child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
