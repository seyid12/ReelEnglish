import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';

class ApiService {
  // Render.com'da yayınlanan canlı (production) backend
   static const String baseUrl = 'https://reelenglish-4.onrender.com';

  // Lokal test için (Localtunnel aracılığıyla Güvenlik Duvarını aşarak):
  //static const String baseUrl = 'https://icy-singers-sniff.loca.lt';

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

  static Future<bool> addVideo(
    VideoModel video, {
    List<dynamic>? words,
    List<dynamic>? quiz,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Kullanıcı giriş yapmamış');
        return false;
      }

      final idToken = await user.getIdToken();

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
        'Bypass-Tunnel-Reminder': 'true',
      };

      final Map<String, dynamic> body = {
        'url': video.videoUrl,
        'difficulty': int.tryParse(video.difficultyLevel.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 1,
        'grammar_tags': video.grammarTopic.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'source_type': video.sourceType,
      };

      if (words != null && words.isNotEmpty) {
        body['words'] = words;
      }
      if (quiz != null && quiz.isNotEmpty) {
        body['quiz'] = quiz;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/videos'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Video başarıyla eklendi');
        return true;
      } else {
        print(
          '❌ Video ekleme hatası: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Video ekleme hatası: $e');
      return false;
    }
  }

  static Future<String?> uploadVideoToFTP(String filePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Kullanıcı giriş yapmamış');
        return null;
      }
      final idToken = await user.getIdToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/videos/upload'),
      );
      request.headers['Authorization'] = 'Bearer $idToken';
      request.headers['Bypass-Tunnel-Reminder'] =
          'true'; // Localtunnel uyarı sayfasını atlamak için
      request.files.add(await http.MultipartFile.fromPath('video', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['url'] as String?;
      } else {
        print('❌ FTP upload hatası: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ FTP upload hatası: $e');
      return null;
    }
  }
}
