import 'dart:async';
import 'package:flutter/foundation.dart';

enum VoiceListeningState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  VoiceListeningState _state = VoiceListeningState.idle;
  String _selectedLanguage = 'en'; // 'en' (English), 'ta' (Tamil), 'ta-en' (Tanglish)
  String _recognizedText = '';
  String _lastAiResponse = '';
  bool _isMuted = false;
  double _waveformLevel = 0.2;
  Timer? _waveformTimer;

  VoiceListeningState get state => _state;
  String get selectedLanguage => _selectedLanguage;
  String get recognizedText => _recognizedText;
  String get lastAiResponse => _lastAiResponse;
  bool get isMuted => _isMuted;
  double get waveformLevel => _waveformLevel;

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void startListening({String? simulatedPreset}) {
    _state = VoiceListeningState.listening;
    _recognizedText = '';
    _startWaveformAnimation();
    notifyListeners();

    // If preset provided or for realistic simulated speech recognition
    if (simulatedPreset != null) {
      Timer(const Duration(milliseconds: 1400), () {
        _recognizedText = simulatedPreset;
        stopListening();
      });
    }
  }

  void stopListening() {
    _waveformTimer?.cancel();
    _state = VoiceListeningState.processing;
    notifyListeners();
  }

  void setManualInput(String text) {
    _recognizedText = text;
    _state = VoiceListeningState.processing;
    notifyListeners();
  }

  void setAiResponse(String response) {
    _lastAiResponse = response;
    _state = _isMuted ? VoiceListeningState.idle : VoiceListeningState.speaking;
    notifyListeners();

    if (!_isMuted) {
      // Simulate TTS playback duration
      Timer(const Duration(seconds: 3), () {
        if (_state == VoiceListeningState.speaking) {
          _state = VoiceListeningState.idle;
          notifyListeners();
        }
      });
    }
  }

  void reset() {
    _waveformTimer?.cancel();
    _state = VoiceListeningState.idle;
    _recognizedText = '';
    _lastAiResponse = '';
    notifyListeners();
  }

  void _startWaveformAnimation() {
    _waveformTimer?.cancel();
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (_state == VoiceListeningState.listening) {
        _waveformLevel = 0.1 + (DateTime.now().millisecond % 90) / 100.0;
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    super.dispose();
  }
}
