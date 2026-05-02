import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class ApiService {
  // Emülatörden localhost'a erişim için 10.0.2.2 kullanılır.
  // Gerçek cihaz testi için bilgisayarınızın yerel IP'sini yazın (Örn: http://192.168.1.5:3000)
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<List<VideoModel>> fetchVideos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/feed')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw Exception('Videolar yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  static Future<void> syncUserProgress({
    required String userId,
    required double focusScore,
    required int sessionDuration,
    required List<String> learnedWords,
    required List<String> struggledGrammar,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/sync-progress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'focus_score': focusScore,
          'session_duration': sessionDuration,
          'learned_words': learnedWords,
          'struggled_grammar': struggledGrammar,
        }),
      ).timeout(const Duration(seconds: 5));
      print("🚀 Backend'e senkronize edildi: Focus Score: $focusScore");
    } catch (e) {
      print('❌ Senkronizasyon hatası: $e');
      throw Exception('Senkronizasyon hatası: $e');
    }
  }
}
