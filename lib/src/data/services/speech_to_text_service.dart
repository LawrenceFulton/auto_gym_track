import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';

abstract class SpeechToTextService {
  Future<void> startListening();
  Future<String> stopListening();
  Future<String> transcribeFromMic();
}

class DeviceSpeechToTextService implements SpeechToTextService {
  DeviceSpeechToTextService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  bool _isListening = false;
  String _lastWords = '';

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    final isAvailable = await _speech.initialize();
    if (!isAvailable) {
      throw Exception('Speech recognition is not available on this device/configuration.');
    }

    _initialized = true;
  }

  @override
  Future<void> startListening() async {
    await _ensureInitialized();

    if (_isListening) {
      return;
    }

    _lastWords = '';
    await _speech.listen(
      listenOptions: SpeechListenOptions(listenMode: ListenMode.confirmation, partialResults: true),
      onResult: (result) {
        _lastWords = result.recognizedWords.trim();
      },
    );

    _isListening = true;
  }

  @override
  Future<String> stopListening() async {
    if (!_isListening) {
      throw Exception('Speech recording is not active.');
    }

    await _speech.stop();
    _isListening = false;

    final transcript = _lastWords.trim();
    if (transcript.isEmpty) {
      throw Exception('No speech was detected.');
    }

    return transcript;
  }

  @override
  Future<String> transcribeFromMic() async {
    await startListening();
    await Future<void>.delayed(const Duration(seconds: 3));
    return stopListening();
  }
}
