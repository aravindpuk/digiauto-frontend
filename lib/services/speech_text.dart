import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  bool isListening = false;
  bool isInitialized = false;

  Future<void> init() async {
    if (!isInitialized) {
      isInitialized = await _speech.initialize(
        onStatus: (status) {
          //  print("STATUS: $status");

          if (status == "notListening") {
            isListening = false;
          }
        },
        onError: (error) {
          //  print("ERROR: $error");
          isListening = false;
        },
      );
    }
  }

  Future<void> startListening(Function(String text) onResult) async {
    if (!isInitialized) return;

    isListening = true;

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
      localeId: "en_IN",
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  void stopListening() {
    _speech.stop();
    isListening = false;
  }
}
