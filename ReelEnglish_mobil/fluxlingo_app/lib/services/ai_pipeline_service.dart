import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

/// Cihaz donanım analizine göre (Edge/Cloud) karar veren ve sesi çıkaran servis.
class AiPipelineService {
  // TODO: Prod ortamında bu API Key güvenli bir yerden (.env veya Backend) çekilmelidir.
  static const _geminiApiKey = 'GEMINI_API_KEY_HERE';

  /// Cihazın NPU (Yapay Zeka Birimi) veya RAM açısından güçlü olup olmadığını kontrol eder.
  Future<bool> _hasNpuOrHighPerformance() async {
    // Gerçek dünyada burada device_info_plus ile iOS'ta A13 Bionic üstü,
    // Android'de NNAPI/Snapdragon 8+ Gen durumu veya RAM >= 6GB kontrol edilir.
    // Şimdilik test amaçlı false dönerek doğrudan Gemini'ye düşmesini sağlıyoruz,
    // çünkü yerel Whisper modelleri henüz tam stabil değil.
    return false;
  }

  /// Verilen MP4 videosundan sadece sesi ayırıp .mp3 olarak kaydeder.
  Future<File?> extractAudioLocally(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final uuid = const Uuid().v4();
      final outputPath = '${tempDir.path}/audio_$uuid.mp3';

      // FFmpeg komutu: Video (-vn), Sadece Ses (-acodec libmp3lame), 16kHz (-ar 16000)
      final command = '-i "${videoFile.path}" -vn -acodec libmp3lame -q:a 2 -ar 16000 "$outputPath"';
      
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return File(outputPath);
      } else {
        final failStackTrace = await session.getFailStackTrace();
        print('FFmpeg Error: $failStackTrace');
        return null;
      }
    } catch (e) {
      print('Audio extraction failed: $e');
      return null;
    }
  }

  /// Yapay zeka sürecini başlatır (Hibrit Yönlendirme)
  Future<Map<String, dynamic>?> processVideoAi(File videoFile) async {
    print("1. Yerel olarak video sesi ayıklanıyor...");
    final audioFile = await extractAudioLocally(videoFile);
    if (audioFile == null) return null;

    print("2. Donanım gücü test ediliyor...");
    final isDevicePowerful = await _hasNpuOrHighPerformance();

    if (isDevicePowerful) {
      print("3. NPU tespit edildi. İşlem cihaz üzerinde yapılacak (Local Model)...");
      return await _processWithLocalModel(audioFile);
    } else {
      print("3. Cihaz yeterince güçlü değil. Gemini API kullanılıyor (Cloud Fallback)...");
      return await _processWithGeminiApi(audioFile);
    }
  }

  /// Güçlü cihazlar için tamamen cihaz içi çalışan dil modeli (Örn: Whisper C++ / Llama.cpp)
  Future<Map<String, dynamic>?> _processWithLocalModel(File audioFile) async {
    // TODO: Kullanıcı onay verirse cihaz içi Whisper modeli (whisper_flutter vb.) buraya eklenecek.
    // Şu an için Flutter paketleri stabil olmadığı için bu kısım mock olarak bırakılmıştır.
    await Future.delayed(const Duration(seconds: 2));
    return {
      "words": [
        {"word": "local", "translation": "yerel"},
        {"word": "processing", "translation": "işleme"}
      ],
      "quiz": [
        {"question": "How did we process this?", "options": ["Cloud", "Local"], "answer": "Local"}
      ]
    };
  }

  /// Zayıf cihazlar veya stabilite için Gemini API'ye başvurma (Fallback)
  Future<Map<String, dynamic>?> _processWithGeminiApi(File audioFile) async {
    if (_geminiApiKey == 'GEMINI_API_KEY_HERE') {
      print("Lütfen Gemini API Key ekleyin!");
      return null;
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _geminiApiKey,
      );

      final audioBytes = await audioFile.readAsBytes();
      final prompt = TextPart(
          "You are an English teacher. I am giving you an audio track from a video. "
          "Listen to it carefully and output a JSON response with two keys:\n"
          "1. 'words': An array of the 5 most important B1-C1 level English vocabulary words found in the audio, along with their Turkish 'translation' and a short English 'example_sentence'.\n"
          "2. 'quiz': An array of 3 multiple-choice questions based on the context of the audio to test comprehension. Each question should have 'question', 'options' (array of 4 strings), and 'answer' (the exact string of the correct option).\n"
          "Output ONLY valid JSON."
      );

      // Sesi veri parçası (DataPart) olarak modele veriyoruz.
      final audioPart = DataPart('audio/mp3', audioBytes);

      final response = await model.generateContent([
        Content.multi([prompt, audioPart])
      ]);

      String text = response.text ?? '';
      // JSON formatından temizle (Markdown taglerini at)
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      print("Gemini API Error: $e");
      return null;
    } finally {
      // Temizlik: Oluşturulan mp3 dosyasını siliyoruz
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    }
  }
}
