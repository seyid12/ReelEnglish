import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/video_model.dart';
import '../../../../services/api_service.dart';
import '../../../../services/auth_service.dart';
import '../widgets/reel_video_player.dart';
import '../../../perception/services/face_detector_service.dart';
import '../../../intervention/services/speech_service.dart';
import '../../../gamification/providers/user_stats_provider.dart';
import '../../../admin/presentation/screens/add_video_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  int _currentIndex = 0;
  bool _isDistracted = false;

  // Backend ve Video State
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  DateTime _videoStartTime = DateTime.now();
  int _distractionCount = 0;

  // Algı Katmanı (Kamera)
  late final FaceDetectorService _faceDetectorService;
  StreamSubscription<bool>? _distractionSub;

  // Müdahale Katmanı (Ses Tanıma)
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  String _spokenText = '';
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.transparent;

  // Oyunlaştırma (Konfeti ve Animasyon)
  late ConfettiController _confettiController;
  bool _showXPAnimation = false;

  // Authentication
  final AuthService _authService = AuthService();

  // PageView Controller
  late PageController _pageController;

  final List<VideoModel> _fallbackMockVideos = [
    VideoModel(
      id: 'mock1',
      videoUrl:
          'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      grammarTopic: 'Present Continuous',
      difficultyLevel: 'A2 (Beginner)',
    ),
    VideoModel(
      id: 'mock2',
      videoUrl:
          'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      grammarTopic: 'Past Simple vs Past Continuous',
      difficultyLevel: 'B1 (Intermediate)',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _faceDetectorService = FaceDetectorService();
    _pageController = PageController(viewportFraction: 1.0);

    _loadVideosFromBackend();
    _initPerception();
    _speechService.initialize();
  }

  Future<void> _loadVideosFromBackend() async {
    try {
      final videos = await ApiService.fetchVideos();
      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
          _videoStartTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sunucuya bağlanılamadı, yerel veriler kullanılıyor.',
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _videos = _fallbackMockVideos;
          _isLoading = false;
          _videoStartTime = DateTime.now();
        });
      }
    }
  }

  Future<void> _initPerception() async {
    await _faceDetectorService.initialize();

    _distractionSub = _faceDetectorService.distractionStream.listen((
      isDistractedSignal,
    ) {
      if (isDistractedSignal && !_isDistracted) {
        _distractionCount++; // Focus skoru hesaplaması için artır
        setState(() {
          _isDistracted = true;
          _spokenText = '';
          _feedbackMessage = '';
          _showXPAnimation = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _distractionSub?.cancel();
    _faceDetectorService.dispose();
    _confettiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Videoyu geçerken arka planda sunucuya verileri yolla
  void _syncProgressForCurrentVideo() {
    if (_videos.isEmpty) return;

    final currentVideo = _videos[_currentIndex % _videos.length];
    final durationInSeconds = DateTime.now()
        .difference(_videoStartTime)
        .inSeconds;

    // Focus skorunu hesapla (örnek: 100 üzerinden, her dikkat dağınıklığında 20 puan düş)
    double focusScore = 100.0 - (_distractionCount * 20.0);
    if (focusScore < 0) focusScore = 0;

    ApiService.syncUserProgress(
      userId: 'test_user_123', // Şimdilik statik test kullanıcısı
      focusScore: focusScore,
      sessionDuration: durationInSeconds,
      learnedWords: [],
      struggledGrammar: focusScore < 50 ? [currentVideo.grammarTopic] : [],
    ).catchError((_) {
      // Hata durumunda sessiz kal, UI'ı bölme
    });
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _spokenText = '';
      _feedbackMessage = '';
      _showXPAnimation = false;
    });

    _speechService.startListening((text) {
      setState(() {
        _spokenText = text;
      });
    });
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() {
      _isListening = false;
    });

    if (_spokenText.isEmpty) return;

    final String targetSentence = "I have been studying for two hours";
    final targetClean = targetSentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
    final spokenClean = _spokenText
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    if (spokenClean.contains(targetClean) ||
        (targetClean.contains(spokenClean) && spokenClean.length > 5)) {
      _confettiController.play();
      ref.read(userStatsProvider.notifier).addXP(50);

      // Başarılı etkileşimi anında backend'e bildir
      ApiService.syncUserProgress(
        userId: 'test_user_123',
        focusScore: 100.0, // Telaffuzu başardı, yüksek odaklanma
        sessionDuration: DateTime.now().difference(_videoStartTime).inSeconds,
        learnedWords: ['success'],
        struggledGrammar: [],
      ).catchError((_) {});

      setState(() {
        _feedbackMessage = 'Harika!';
        _feedbackColor = Colors.greenAccent;
        _showXPAnimation = true;
      });

      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _isDistracted = false;
            _showXPAnimation = false;
            _distractionCount = 0; // Yeni tur için sıfırla
            _videoStartTime = DateTime.now();
          });
        }
      });
    } else {
      setState(() {
        _feedbackMessage = 'Tekrar Dene';
        _feedbackColor = Colors.redAccent;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }

    if (_videos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Gösterilecek video bulunamadı.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Kullanıcı giriş yaptı mı kontrol et
    final isUserAuthenticated = _authService.currentUser != null;

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: isUserAuthenticated
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddVideoScreen()),
                ).then((_) {
                  _loadVideosFromBackend();
                });
              },
              backgroundColor: Colors.amber,
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: _isDistracted
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            onPageChanged: (index) {
              HapticFeedback.lightImpact();

              // Sayfa değiştiğinde eski videonun progress verisini senkronize et
              _syncProgressForCurrentVideo();

              setState(() {
                _currentIndex = index;
                _videoStartTime = DateTime.now();
                _distractionCount = 0; // Yeni video için sıfırla
              });
            },
            itemBuilder: (context, index) {
              final actualIndex = index % _videos.length;
              final video = _videos[actualIndex];
              final isActive = index == _currentIndex;

              return ReelVideoPlayer(
                video: video,
                isActive: isActive,
                isDistracted: _isDistracted,
              );
            },
          ),

          if (!_isDistracted) _buildTopBar(),

          if (!_isDistracted)
            Positioned(
              top: 55,
              right: 60,
              child: IconButton(
                icon: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.white54,
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    _distractionCount++; // Manuel testte de artsın
                    _isDistracted = true;
                    _spokenText = '';
                    _feedbackMessage = '';
                    _showXPAnimation = false;
                  });
                },
              ),
            ),

          if (!_isDistracted)
            Positioned(
              top: 55,
              right: 16,
              child: _buildAuthButton(),
            ),

          if (_isDistracted)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                  child: Center(child: _buildDistractionCard()),
                ),
              ),
            ),

          if (_showXPAnimation) _buildXPAnimation(),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              gravity: 0.2,
              emissionFrequency: 0.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final stats = ref.watch(userStatsProvider);
    final progress = (stats.currentXP % 500) / 500.0;

    return Positioned(
      top: 65,
      left: 16,
      right: 70,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Text(
              'Lvl ${stats.userLevel}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(progress > 0 ? 0.3 : 0),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPAnimation() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      bottom: _showXPAnimation
          ? MediaQuery.of(context).size.height / 2 + 100
          : MediaQuery.of(context).size.height / 2,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1000),
        opacity: _showXPAnimation ? 1.0 : 0.0,
        child: const Text(
          '+50 XP',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.amberAccent,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Colors.black87,
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
              Shadow(
                color: Colors.orangeAccent,
                blurRadius: 20,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistractionCard() {
    final String targetSentence = "I have been studying for two hours.";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDistracted = false;
                  _distractionCount = 0;
                  _videoStartTime = DateTime.now();
                });
              },
              child: const Icon(Icons.close, color: Colors.white54, size: 28),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 56,
              color: Colors.cyanAccent,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Hey, dikkatini kaybettin!\nSıra sende.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Text(
              '"$targetSentence"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_spokenText.isNotEmpty || _feedbackMessage.isNotEmpty)
            Column(
              children: [
                Text(
                  _spokenText,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (_feedbackMessage.isNotEmpty)
                  Text(
                    _feedbackMessage,
                    style: TextStyle(
                      color: _feedbackColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 20),

          AvatarGlow(
            animate: _isListening,
            glowColor: Colors.redAccent,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            child: GestureDetector(
              onTapDown: (_) => _startListening(),
              onTapUp: (_) => _stopListening(),
              onTapCancel: () => _stopListening(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blueAccent, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.mic, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Basılı Tut ve Konuş',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton() {
    final isUserAuthenticated = _authService.currentUser != null;

    if (isUserAuthenticated) {
      return IconButton(
        icon: const Icon(
          Icons.logout,
          color: Colors.red,
          size: 28,
        ),
        tooltip: 'Çıkış Yap',
        onPressed: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Uygulamadan çıkış yapmak istediğinize emin misiniz?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('İptal', style: TextStyle(color: Colors.amber)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            try {
              await _authService.signOut();
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Başarıyla çıkış yapıldı.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Çıkış yapılırken hata oluştu: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      );
    } else {
      return IconButton(
        icon: const Icon(
          Icons.lock_outline,
          color: Colors.amber,
          size: 28,
        ),
        tooltip: 'Admin Giriş',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      );
    }
  }
}
