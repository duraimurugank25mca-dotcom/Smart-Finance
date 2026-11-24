import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: 'Hello! I am your Smart Finance AI Assistant. Ask me anything about your balances, spending, wastage, or savings.',
      isUser: false,
    ),
  ];

  Map<String, dynamic>? _wastageReport;
  Map<String, dynamic>? _incomeReport;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  Map<String, dynamic>? get wastageReport => _wastageReport;
  Map<String, dynamic>? get incomeReport => _incomeReport;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  String? get errorMessage => _errorMessage;

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(text: text.trim(), isUser: true));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final answer = await _api.askAiAssistant(text.trim());
      _messages.add(ChatMessage(text: answer, isUser: false));
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'Apologies, I encountered an issue analyzing your data: ${e.toString().replaceAll('Exception: ', '')}',
        isUser: false,
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> runFullAnalysis() async {
    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _api.analyseFinancials();
      _wastageReport = data['wastage'];
      _incomeReport = data['incomeAnalysis'];
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }
}
