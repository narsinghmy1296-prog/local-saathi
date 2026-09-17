import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Thin wrapper around speech_to_text (which itself wraps Android's
/// SpeechRecognizer). Recognized text is only ever *shown* to the customer
/// for confirm/retry/edit — it never triggers a search or cart action by
/// itself, per spec.
class VoiceSearchController extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool available = false;
  bool listening = false;
  String recognizedText = '';
  String? error;

  Future<bool> init() async {
    try {
      available = await _speech.initialize(
        onError: (e) {
          error = e.errorMsg;
          listening = false;
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            listening = false;
            notifyListeners();
          }
        },
      );
    } catch (e) {
      available = false;
      error = e.toString();
    }
    notifyListeners();
    return available;
  }

  /// [localeId] lets the caller pick Hindi ("hi_IN"), English ("en_IN"/"en_US"),
  /// or leave null for the device's current input-language setting — the
  /// spec asks for Hindi/English/Hinglish "where device speech recognition
  /// supports it", so we don't force a single locale.
  Future<void> startListening({String? localeId}) async {
    if (!available) {
      final ok = await init();
      if (!ok) return;
    }
    recognizedText = '';
    error = null;
    listening = true;
    notifyListeners();
    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        recognizedText = result.recognizedWords;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    listening = false;
    notifyListeners();
  }

  void reset() {
    recognizedText = '';
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
