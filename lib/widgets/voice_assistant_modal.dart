import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';
import '../services/api_service.dart';
import '../providers/finance_provider.dart';
import '../core/theme/app_theme.dart';
import 'transaction_preview_dialog.dart';

class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _manualTextController = TextEditingController();
  final ApiService _api = ApiService();

  final List<String> _sampleVoiceCommands = [
    'Add 5000 rupees salary income',
    'Add 200 rupees petrol expense',
    'What is my balance?',
    'What is my total income this month?',
    'Add bike EMI of 4500 rupees due on 20th November',
    'Generate report from Nov 1 to Nov 16',
    '5000 roobai salary income add pannu',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _manualTextController.dispose();
    super.dispose();
  }

  Future<void> _processVoiceText(String text, VoiceService voice) async {
    voice.setManualInput(text);

    try {
      final res = await _api.parseVoiceCommand(text, language: voice.selectedLanguage);
      final respText = res['response_text'] ?? 'Command processed.';
      voice.setAiResponse(respText);

      // If action requires confirmation (Add Income, Add Expense, Add EMI)
      if (res['requires_confirmation'] == true && res['data'] != null && mounted) {
        final txData = res['data'];
        final isIncome = txData['type'] == 'income';

        final confirmed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => TransactionPreviewDialog(
            title: isIncome ? 'Confirm New Income' : 'Confirm New Expense',
            type: txData['type'] ?? 'expense',
            initialAmount: double.tryParse(txData['amount'].toString()) ?? 100.0,
            initialCategory: txData['category_name'] ?? (isIncome ? 'Salary' : 'Other expenses'),
            initialPaymentMethod: txData['payment_method'] ?? 'UPI',
            initialDate: txData['transaction_date'] ?? DateTime.now().toIso8601String().substring(0, 10),
            initialDescription: txData['description'] ?? 'Voice Transaction',
            onConfirm: ({
              required double amount,
              required String category,
              required String paymentMethod,
              required String date,
              required String description,
            }) async {
              final fin = Provider.of<FinanceProvider>(context, listen: false);
              final cat = fin.categories.firstWhere(
                (c) => c.name.toLowerCase() == category.toLowerCase(),
                orElse: () => fin.categories.first,
              );

              await fin.addTransaction(
                categoryId: cat.id,
                type: txData['type'] ?? 'expense',
                amount: amount,
                transactionDate: date,
                paymentMethod: paymentMethod,
                description: description,
              );
            },
          ),
        );

        if (confirmed == true && mounted) {
          voice.setAiResponse('Transaction confirmed and successfully saved to your ledger.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppTheme.incomeGreenDark,
              content: Text('Transaction successfully recorded!'),
            ),
          );
        }
      }
    } catch (e) {
      voice.setAiResponse('Error executing voice command: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = Provider.of<VoiceService>(context);
    final isListening = voice.state == VoiceListeningState.listening;
    final isSpeaking = voice.state == VoiceListeningState.speaking;
    final isProcessing = voice.state == VoiceListeningState.processing;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header & Language Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mic_rounded, color: AppTheme.primaryPurple, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'AI Voice Assistant',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textDarkNavy),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Language Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.purplePillBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.purpleBorder),
                      ),
                      child: DropdownButton<String>(
                        value: voice.selectedLanguage,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        icon: const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.primaryPurple),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                          DropdownMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                          DropdownMenuItem(value: 'tanglish', child: Text('Tanglish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple))),
                        ],
                        onChanged: (val) {
                          if (val != null) voice.setLanguage(val);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(voice.isMuted ? Icons.volume_off : Icons.volume_up, size: 20, color: AppTheme.primaryPurple),
                      onPressed: voice.toggleMute,
                      tooltip: voice.isMuted ? 'Unmute TTS' : 'Mute TTS',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Animated Mic Button / Waveform
            Stack(
              alignment: Alignment.center,
              children: [
                if (isListening)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (ctx, child) {
                      return Container(
                        width: 90 + (_pulseController.value * 25),
                        height: 90 + (_pulseController.value * 25),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryPurple.withOpacity(0.25 * (1 - _pulseController.value)),
                        ),
                      );
                    },
                  ),
                GestureDetector(
                  onTap: () {
                    if (isListening) {
                      voice.stopListening();
                    } else {
                      final randomSample = _sampleVoiceCommands[DateTime.now().second % _sampleVoiceCommands.length];
                      voice.startListening(simulatedPreset: randomSample);
                      Timer(const Duration(milliseconds: 1500), () {
                        _processVoiceText(randomSample, voice);
                      });
                    }
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isListening
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [AppTheme.primaryPurple, AppTheme.primaryPurpleDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isListening ? Colors.red : AppTheme.primaryPurple).withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Waveform indicator
            if (isListening)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(7, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: 12 + ((i * 7 + (voice.waveformLevel * 20)) % 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),

            Text(
              isListening
                  ? 'Listening... Speak now or tap to stop'
                  : isProcessing
                      ? 'AI is understanding your voice command...'
                      : isSpeaking
                          ? 'Speaking AI response...'
                          : 'Tap microphone to speak',
              style: TextStyle(
                fontSize: 13,
                color: isListening ? AppTheme.primaryPurple : AppTheme.textSecondary,
                fontWeight: isListening ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 16),

            // Recognized Speech Box
            if (voice.recognizedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.appBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recognized Speech:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${voice.recognizedText}"',
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.textDarkNavy),
                    ),
                  ],
                ),
              ),

            // AI Response Box
            if (voice.lastAiResponse.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.purplePillBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.purpleBorder, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Assistant:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple),
                        ),
                        IconButton(
                          icon: const Icon(Icons.replay_rounded, size: 16, color: AppTheme.primaryPurple),
                          onPressed: () => voice.setAiResponse(voice.lastAiResponse),
                          tooltip: 'Repeat Voice',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voice.lastAiResponse,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDarkNavy),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Sample voice commands chips
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Try Voice Commands:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sampleVoiceCommands.map((cmd) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(
                        cmd,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryPurple),
                      ),
                      backgroundColor: AppTheme.purplePillBg,
                      side: const BorderSide(color: AppTheme.purpleBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () {
                        voice.startListening(simulatedPreset: cmd);
                        _processVoiceText(cmd, voice);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Manual Text Input fallback
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualTextController,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textDarkNavy),
                    decoration: InputDecoration(
                      hintText: 'Type voice instruction manually...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      isDense: true,
                      fillColor: AppTheme.appBackground,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5),
                      ),
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        _processVoiceText(val.trim(), voice);
                        _manualTextController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                    onPressed: () {
                      if (_manualTextController.text.trim().isNotEmpty) {
                        _processVoiceText(_manualTextController.text.trim(), voice);
                        _manualTextController.clear();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
