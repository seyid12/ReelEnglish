import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) => print('Ses tanıma hatası: $error'),
      onStatus: (status) => print('Ses tanıma durumu: $status'),
    );
    return _isInitialized;
  }

  void startListening(Function(String) onResult) {
    if (!_isInitialized) return;
    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: 'en_US', // İngilizce telaffuz testi için
      cancelOnError: true,
      partialResults: true,
    );
  }

  void stopListening() {
    _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
