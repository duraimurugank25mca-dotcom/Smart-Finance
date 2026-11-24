import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import '../transactions/transactions_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/voice_assistant_modal.dart';
import '../../routes/app_routes.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    AiAssistantScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  void _openVoiceAssistant() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const VoiceAssistantModal(),
    );
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Financial Quick Actions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDarkNavy),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.incomeGreenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.incomeGreenDark),
                ),
                title: const Text('Add Income', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Salary, Freelance, Dividends', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.addTransaction, arguments: {'type': 'income'});
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.expenseRedBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.expenseRedDark),
                ),
                title: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Food, Fuel, Shopping, Bills', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.addTransaction, arguments: {'type': 'expense'});
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.purplePillBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryPurple),
                ),
                title: const Text('Scan Bill (Camera)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Scan receipt with live camera viewfinder & OCR', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.billScanner, arguments: {'mode': 'scan'});
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.purpleLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primaryPurple),
                ),
                title: const Text('Upload Bill (Gallery & Files)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Upload photo or PDF receipts from storage', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, AppRoutes.billScanner, arguments: {'mode': 'upload'});
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.purpleLightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.mic_rounded, color: AppTheme.primaryPurple),
                ),
                title: const Text('Voice Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Natural voice commands in English & Tamil', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openVoiceAssistant();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isDesktop = constraints.maxWidth >= 960;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppTheme.appBackground,
            body: Row(
              children: [
                // DESKTOP SIDEBAR (Exact Duolink Navigation Structure from Image 2 & 3)
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: AppTheme.cardBorder, width: 1.2)),
                  ),
                  child: Column(
                    children: [
                      // Brand Header
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 20, left: 20, right: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2E0854), Color(0xFF6D28D9)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryPurple.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SMART FINANCE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                                Text(
                                  'FINANCE MANAGER',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: AppTheme.cardBorder),

                      // Navigation Sections
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSidebarSectionLabel('MAIN MENU'),
                              _buildSidebarItem(
                                index: 0,
                                icon: Icons.grid_view_rounded,
                                label: 'Dashboard',
                              ),
                              _buildSidebarItem(
                                index: 1,
                                icon: Icons.receipt_long_rounded,
                                label: 'Transactions',
                              ),
                              _buildSidebarItem(
                                index: 2,
                                icon: Icons.auto_awesome_rounded,
                                label: 'AI Assistant',
                              ),
                              _buildSidebarItem(
                                index: 3,
                                icon: Icons.insert_chart_outlined_rounded,
                                label: 'Reports & Analytics',
                              ),

                              const SizedBox(height: 14),
                              _buildSidebarSectionLabel('ADMINISTRATION'),
                              _buildExternalSidebarItem(
                                icon: Icons.qr_code_scanner_rounded,
                                label: 'Bill Scanner',
                                onTap: () => Navigator.pushNamed(context, AppRoutes.billScanner),
                              ),
                              _buildExternalSidebarItem(
                                icon: Icons.account_balance_outlined,
                                label: 'EMI Commitments',
                                onTap: () => Navigator.pushNamed(context, AppRoutes.emi),
                              ),
                              _buildExternalSidebarItem(
                                icon: Icons.pie_chart_outline_rounded,
                                label: 'Budgets',
                                onTap: () => Navigator.pushNamed(context, AppRoutes.budgets),
                              ),
                              _buildExternalSidebarItem(
                                icon: Icons.savings_outlined,
                                label: 'Savings Goals',
                                onTap: () => Navigator.pushNamed(context, AppRoutes.savings),
                              ),
                              if (user?.isAdmin ?? false)
                                _buildExternalSidebarItem(
                                  icon: Icons.admin_panel_settings_rounded,
                                  label: 'User Management',
                                  onTap: () => Navigator.pushNamed(context, AppRoutes.adminDashboard),
                                ),

                              const SizedBox(height: 14),
                              _buildSidebarSectionLabel('ACCOUNT'),
                              _buildSidebarItem(
                                index: 4,
                                icon: Icons.settings_outlined,
                                label: 'Profile & Security',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 1, color: AppTheme.cardBorder),

                      // Bottom User Profile Snippet (Matching Image 2 & 5)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (user?.fullName.isNotEmpty ?? false) ? user!.fullName[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user?.fullName ?? 'User',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDarkNavy),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (user?.isAdmin ?? false) ? AppTheme.primaryPurpleDeep : AppTheme.purplePillBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user?.role ?? 'USER',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: (user?.isAdmin ?? false) ? Colors.white : AppTheme.primaryPurple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.textMuted),
                              tooltip: 'Logout',
                              onPressed: () async {
                                await auth.logout();
                                if (context.mounted) {
                                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENT AREA
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }

        // MOBILE LAYOUT
        return Scaffold(
          backgroundColor: AppTheme.appBackground,
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          floatingActionButton: FloatingActionButton(
            elevation: 4,
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: _showQuickActionSheet,
            tooltip: 'Quick Actions',
            child: const Icon(Icons.add, size: 28),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.white,
            elevation: 3,
            selectedIndex: _currentIndex,
            indicatorColor: AppTheme.purplePillBg,
            onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryPurple),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryPurple),
                label: 'Transactions',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryPurple),
                label: 'AI Assistant',
              ),
              NavigationDestination(
                icon: Icon(Icons.pie_chart_outline_rounded),
                selectedIcon: Icon(Icons.pie_chart_rounded, color: AppTheme.primaryPurple),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primaryPurple),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebarSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.purplePillBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryPurple : AppTheme.textDarkNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalSidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDarkNavy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
