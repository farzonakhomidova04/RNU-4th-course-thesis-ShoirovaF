import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> init() async {
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text, String languageCode) async {
    // Map our app locale to standard TTS locales
    String ttsLang = 'en-US';
    if (languageCode == 'ru') ttsLang = 'ru-RU';
    if (languageCode == 'uz') ttsLang = 'tr-TR'; // Fallback for Uzbek if not natively supported, or just use ru-RU

    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
