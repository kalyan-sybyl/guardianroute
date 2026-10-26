import 'package:flutter_tts/flutter_tts.dart';
import 'package:guardianroute/core/services/app_logger.dart';

class NavigationVoiceService {
  NavigationVoiceService() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _initialized = false;
  String? _lastSpokenKey;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  Future<void> speakHazardWarning({
    required String hazardKey,
    required String typeLabel,
    required int distanceMeters,
  }) async {
    if (_lastSpokenKey == hazardKey) return;

    try {
      await ensureInitialized();
      _lastSpokenKey = hazardKey;
      final distancePhrase =
          distanceMeters >= 1000 ? '${(distanceMeters / 1000).toStringAsFixed(1)} kilometers' : '$distanceMeters meters';
      await _tts.speak(
        'Danger ahead. $typeLabel in $distancePhrase. Reduce speed.',
      );
    } catch (e, st) {
      appLogger.w('TTS failed: $e\n$st');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _lastSpokenKey = null;
  }

  void resetCooldown() {
    _lastSpokenKey = null;
  }
}
