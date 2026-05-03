import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';

class ApiService {
  // Render.com'da yayınlanan canlı (production) backend
  static const String baseUrl = 'https://reelenglish-4.onrender.com';

  static Future<List<VideoModel>> fetchVideos() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/feed'))
          .timeout(const Duration(seconds: 5));
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
      await http
          .post(
            Uri.parse('$baseUrl/sync-progress'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'user_id': userId,
              'focus_score': focusScore,
              'session_duration': sessionDuration,
              'learned_words': learnedWords,
              'struggled_grammar': struggledGrammar,
            }),
          )
          .timeout(const Duration(seconds: 5));
      print("🚀 Backend'e senkronize edildi: Focus Score: $focusScore");
    } catch (e) {
      print('❌ Senkronizasyon hatası: $e');
      throw Exception('Senkronizasyon hatası: $e');
    }
  }
  static Future<bool> addVideo(VideoModel video) async {
    try {
      // Firebase'den ID Token al
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Kullanıcı giriş yapmamış');
        return false;
      }

      final idToken = await user.getIdToken();

      // Headers'a Authorization token ekle
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/videos'),
        headers: headers,
        body: json.encode({
          'url': video.videoUrl,
          'difficulty': video.difficultyLevel is int ? video.difficultyLevel : int.tryParse(video.difficultyLevel.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
          'grammar_tags': video.grammarTopic.split(',').map((e) => e.trim()).toList(),
          'source_type': 'youtube',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Video başarıyla eklendi');
        return true;
      } else {
        print('❌ Video ekleme hatası: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Video ekleme hatası: $e');
      return false;
    }
  }
}
