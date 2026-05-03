import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/quiz.dart';
import '../../../gamification/providers/user_stats_provider.dart';
import '../../services/quiz_service.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String videoId;
  final String videoTitle;

  const QuizScreen({
    super.key,
    required this.videoId,
    required this.videoTitle,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  late Future<List<Quiz>> _quizzesFuture;
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _answered = false;
  bool _isCorrect = false;
  List<Quiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _quizzesFuture = QuizService.getQuizzesByVideoId(widget.videoId);
  }

  void _handleAnswerSelection(int index) {
    if (_answered) return; // Zaten cevap verdiyse tekrar tıklasın

    setState(() {
      _selectedAnswerIndex = index;
      _answered = true;
      _isCorrect = index == _quizzes[_currentQuestionIndex].correctAnswerIndex;
    });

    // Doğru cevapsa XP kazandır
    if (_isCorrect) {
      ref.read(userStatsProvider.notifier).addXP(100);
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizzes.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _answered = false;
      });
    } else {
      // Quiz bitti
      Navigator.pop(context, {'completed': true, 'score': _currentQuestionIndex});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Quiz>>(
      future: _quizzesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(widget.videoTitle),
            ),
            body: const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(widget.videoTitle),
            ),
            body: Center(
              child: Text(
                'Sorular yüklenemedi',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        _quizzes = snapshot.data ?? [];

        if (_quizzes.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(widget.videoTitle),
            ),
            body: const Center(
              child: Text(
                'Bu video için soru bulunmuyor',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        final quiz = _quizzes[_currentQuestionIndex];
        final progressPercentage = ((_currentQuestionIndex + 1) / _quizzes.length) * 100;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Soru ${_currentQuestionIndex + 1}/${_quizzes.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İlerleme Çubuğu
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 24),

                  // Soru
                  Text(
                    quiz.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Seçenekler
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quiz.options.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedAnswerIndex == index;
                      final isCorrectAnswer = index == quiz.correctAnswerIndex;
                      Color borderColor = Colors.white24;
                      Color backgroundColor = Colors.transparent;

                      if (_answered) {
                        if (isCorrectAnswer) {
                          borderColor = Colors.green;
                          backgroundColor = Colors.green.withOpacity(0.1);
                        } else if (isSelected && !_isCorrect) {
                          borderColor = Colors.red;
                          backgroundColor = Colors.red.withOpacity(0.1);
                        }
                      } else {
                        if (isSelected) {
                          borderColor = Colors.amber;
                          backgroundColor = Colors.amber.withOpacity(0.1);
                        }
                      }

                      return GestureDetector(
                        onTap: () => _handleAnswerSelection(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index), // A, B, C, D
                                    style: TextStyle(
                                      color: borderColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  quiz.options[index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_answered && isCorrectAnswer)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                )
                              else if (_answered && isSelected && !_isCorrect)
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Açıklama (yanlış cevapsa)
                  if (_answered && !_isCorrect)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '❌ Yanlış Cevap',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            quiz.explanation,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_answered && _isCorrect)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '✅ Doğru! +100 XP',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Next Butonu
                  if (_answered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentQuestionIndex == _quizzes.length - 1
                              ? 'Quiz\'i Tamamla'
                              : 'Sonraki Soru',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
