import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../core/theme/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedQuestions = [
    'How much did I spend today?',
    'What is my total income this month?',
    'Which category has the highest expense?',
    'How much can I save next month?',
    'How can I reduce wastage?',
    'Compare this month and last month',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AiProvider>(context, listen: false).runFullAnalysis();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text, AiProvider ai) {
    if (text.trim().isEmpty) return;
    ai.sendMessage(text.trim());
    _chatController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final ai = Provider.of<AiProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryPurple, size: 22),
            SizedBox(width: 8),
            Text(
              'AI Financial Assistant',
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
            Tab(icon: Icon(Icons.chat_bubble_outline), text: 'AI Chat'),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Wastage Analysis'),
            Tab(icon: Icon(Icons.trending_up_rounded), text: 'Income Growth'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textDarkNavy),
            tooltip: 'Re-analyze Financials',
            onPressed: () => ai.runFullAnalysis(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. AI CHAT TAB
          _buildChatTab(ai),

          // 2. WASTAGE COST ANALYSIS TAB
          _buildWastageTab(ai),

          // 3. INCOME IMPROVEMENT TAB
          _buildIncomeTab(ai),
        ],
      ),
    );
  }

  // 1. CHAT TAB
  Widget _buildChatTab(AiProvider ai) {
    return Column(
      children: [
        // Suggested questions horizontal chips
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1.2)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: _suggestedQuestions.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      q,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                    backgroundColor: AppTheme.purplePillBg,
                    side: const BorderSide(color: AppTheme.purpleBorder, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _sendMessage(q, ai),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Message Thread
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            itemCount: ai.messages.length,
            itemBuilder: (ctx, idx) {
              final msg = ai.messages[idx];
              return _buildMessageBubble(msg);
            },
          ),
        ),

        if (ai.isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI is analyzing your actual transaction history...',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.9)),
                ),
              ],
            ),
          ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.cardBorder, width: 1.2)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textDarkNavy),
                    decoration: InputDecoration(
                      hintText: 'Ask financial questions...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      isDense: true,
                      fillColor: AppTheme.appBackground,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) => _sendMessage(val, ai),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(_chatController.text, ai),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primaryPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppTheme.cardBorder, width: 1.2),
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppTheme.textDarkNavy,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // 2. WASTAGE TAB
  Widget _buildWastageTab(AiProvider ai) {
    if (ai.isAnalyzing) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
    }

    final wastage = ai.wastageReport;
    if (wastage == null) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () => ai.runFullAnalysis(),
          child: const Text('Analyze Wastage & Cost Inefficiencies'),
        ),
      );
    }

    final potentialSavings = double.tryParse(wastage['estimated_monthly_wastage_potential']?.toString() ?? '0') ?? 0.0;
    final discretionaryTotal = double.tryParse(wastage['discretionary_total']?.toString() ?? '0') ?? 0.0;
    final discretionaryPct = double.tryParse(wastage['discretionary_percentage']?.toString() ?? '0') ?? 0.0;
    final recommendations = (wastage['recommendations'] as List<dynamic>? ?? []).cast<String>();
    final anomalies = (wastage['anomalies'] as List<dynamic>? ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Potential Savings Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.savings_outlined, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'ESTIMATED MONTHLY WASTAGE POTENTIAL',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '₹ ${potentialSavings.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discretionary spends: ₹ ${discretionaryTotal.toStringAsFixed(0)} ($discretionaryPct% of total expenses)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Actionable Cost-Saving Recommendations
          const Text(
            'Actionable Cost-Saving Recommendations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 12),

          ...recommendations.map(
            (rec) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.incomeGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppTheme.incomeGreenDark, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDarkNavy),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 22),

          // High Spend Anomaly Detection
          const Text(
            'High-Spending Anomalies Detected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 12),

          if (anomalies.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: const Center(
                child: Text(
                  'No sudden unusually high single expense anomalies detected this month.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...anomalies.map((a) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.expenseRedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.trending_up, color: AppTheme.expenseRedDark, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹ ${a['amount']} on ${a['category']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDarkNavy),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a['insight'] ?? a['description'] ?? '',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // 3. INCOME IMPROVEMENT TAB
  Widget _buildIncomeTab(AiProvider ai) {
    if (ai.isAnalyzing) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple));
    }

    final income = ai.incomeReport;
    if (income == null) {
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryPurple,
            foregroundColor: Colors.white,
          ),
          onPressed: () => ai.runFullAnalysis(),
          child: const Text('Analyze Income & Savings Opportunities'),
        ),
      );
    }

    final currentRate = double.tryParse(income['current_savings_rate']?.toString() ?? '0') ?? 0.0;
    final emergencyFund = double.tryParse(income['recommended_emergency_fund']?.toString() ?? '0') ?? 0.0;
    final strategies = (income['strategies'] as List<dynamic>? ?? []).cast<String>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Savings Rate Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'CURRENT SAVINGS RATE',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$currentRate%',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Recommended Emergency Buffer: ₹ ${emergencyFund.toStringAsFixed(0)} (3 months baseline)',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Income & Savings Strategies',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDarkNavy),
          ),
          const SizedBox(height: 12),

          ...strategies.map(
            (s) => Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder, width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.advancesGoldBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lightbulb_outline, color: AppTheme.advancesGold, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(fontSize: 13, height: 1.4, color: AppTheme.textDarkNavy),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
