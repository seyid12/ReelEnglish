import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/quiz.dart';

class QuizService {
  static const String baseUrl = 'https://reelenglish-4.onrender.com';

  /// Belirli bir video için soruları getir
  static Future<List<Quiz>> getQuizzesByVideoId(String videoId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/quizzes?video_id=$videoId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Quiz.fromJson(json)).toList();
      } else {
        throw Exception('Sorular yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// Quiz cevabını backend'e gönder ve score al
  static Future<Map<String, dynamic>> submitQuizAnswer({
    required String quizId,
    required int selectedAnswerIndex,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/quiz-submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quiz_id': quizId,
          'selected_answer_index': selectedAnswerIndex,
          'user_id': userId,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Cevap gönderilemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }
}
