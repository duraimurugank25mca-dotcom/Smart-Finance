import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  bool _isLoading = false;
  Map<String, dynamic>? _analytics;
  List<dynamic> _users = [];
  final TextEditingController _userSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final analyticsData = await _api.getAdminAnalytics();
      final usersData = await _api.getAdminUsers(search: _userSearchCtrl.text.trim());
      setState(() {
        _analytics = analyticsData;
        _users = usersData['users'] ?? [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed loading admin data: ${e.toString()}'),
            backgroundColor: AppTheme.expenseRedDark,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    final newStatus = !currentStatus;
    try {
      await _api.toggleUserStatus(userId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: newStatus ? AppTheme.incomeGreenDark : AppTheme.expenseRedDark,
            content: Text('User account has been ${newStatus ? 'activated' : 'deactivated'}.'),
          ),
        );
      }
      _loadAdminData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: ${e.toString()}'),
            backgroundColor: AppTheme.expenseRedDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryPurple, size: 22),
            SizedBox(width: 8),
            Text(
              'Admin Console',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDarkNavy,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryPurple,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.people_outline_rounded), text: 'Users Management'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'System Analytics'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: AppTheme.purplePillBg,
                side: const BorderSide(color: AppTheme.purpleBorder),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.home_outlined, size: 14, color: AppTheme.primaryPurple),
              label: const Text('User Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.mainShell),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.expenseRedDark),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
          : TabBarView(
              controller: _tabController,
              children: [
                // 1. USERS TAB
                _buildUsersTab(),

                // 2. ANALYTICS TAB
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Privacy Banner (Matching Reference Lavender Pill Box)
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.purplePillBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.purpleBorder, width: 1.2),
          ),
          child: const Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryPurple, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Privacy Safeguard Active: Administrators can manage user accounts and system metrics without inspecting private financial transaction records.',
                  style: TextStyle(fontSize: 12, height: 1.35, color: AppTheme.textDarkNavy, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _userSearchCtrl,
            style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy),
            decoration: InputDecoration(
              hintText: 'Search registered user by name or email...',
              hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
              isDense: true,
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
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
            onSubmitted: (_) => _loadAdminData(),
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAdminData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (ctx, idx) {
                final u = _users[idx];
                final isActive = u['is_active'] == true;
                final role = u['role'] ?? 'USER';

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // User Initial Circle Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: role == 'ADMIN' ? AppTheme.primaryPurple : AppTheme.purplePillBg,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (u['full_name'] as String? ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              color: role == 'ADMIN' ? Colors.white : AppTheme.primaryPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  u['full_name'] ?? 'User',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDarkNavy),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: role == 'ADMIN' ? AppTheme.primaryPurpleDeep : AppTheme.purplePillBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: role == 'ADMIN' ? Colors.white : AppTheme.primaryPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${u['email']} • TXs: ${u['transaction_count'] ?? 0}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isActive,
                        activeColor: AppTheme.primaryPurple,
                        onChanged: (val) => _toggleUserStatus(u['id'], isActive),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final uStats = _analytics?['users'];
    final txStats = _analytics?['transactions'];
    final emiStats = _analytics?['emis'];
    final scanStats = _analytics?['scans'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Health & Platform Metrics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 16),

          // User statistics card (Matching Reference Image 2 Metric Style)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 3.5, color: AppTheme.primaryPurple),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registered User Accounts',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDarkNavy),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricColumn('Total Users', uStats?['total_users']?.toString() ?? '0', AppTheme.primaryPurple),
                          _buildMetricColumn('Active Users', uStats?['active_users']?.toString() ?? '0', AppTheme.incomeGreen),
                          _buildMetricColumn('Deactivated', uStats?['deactivated_users']?.toString() ?? '0', AppTheme.expenseRed),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Platform transaction stats
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 3.5, color: AppTheme.incomeGreen),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Global Transaction Volume',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textDarkNavy),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetricColumn('Total Records', txStats?['total_transactions']?.toString() ?? '0', AppTheme.primaryPurple),
                          _buildMetricColumn('Income Credits', txStats?['income_transactions']?.toString() ?? '0', AppTheme.incomeGreen),
                          _buildMetricColumn('Expense Debits', txStats?['expense_transactions']?.toString() ?? '0', AppTheme.expenseRed),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // EMIs and Bill Scans row
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(height: 3.5, color: AppTheme.advancesGold),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Active Loan Commitments', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(
                              emiStats?['active_emis']?.toString() ?? '0',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.advancesGold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(height: 3.5, color: AppTheme.purpleGlow),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Total OCR Bill Scans', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text(
                              scanStats?['total_scans']?.toString() ?? '0',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primaryPurple),
                            ),
                          ],
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
    );
  }

  Widget _buildMetricColumn(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
