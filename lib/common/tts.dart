import 'dart:async';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

class TTS {
  static final TTS _instance = TTS._internal();

  factory TTS() => _instance;

  static FlutterTts? _tts;

  TTS._internal();

  Future<FlutterTts> get get async {
    if (_tts != null) return _tts!;
    _tts = await _initTTS();
    return _tts!;
  }

  Future<FlutterTts> _initTTS() async {
    FlutterTts tts = FlutterTts();
    if (await tts.isLanguageAvailable("hu-HU")) {
      await tts.setLanguage("hu-HU");
    } else {
      await tts.setLanguage("en-US");
    }
    await tts.setSpeechRate(1);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.awaitSpeakCompletion(true);
    if (Platform.isIOS) {
      await tts.setSharedInstance(true);
      await tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt);
    }
    return tts;
    
  }
}
