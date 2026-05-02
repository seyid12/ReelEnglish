import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../models/video_model.dart';

class ReelVideoPlayer extends StatefulWidget {
  final VideoModel video;
  final bool isActive;
  final bool isDistracted;

  const ReelVideoPlayer({
    super.key,
    required this.video,
    required this.isActive,
    required this.isDistracted,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  // Firebase/.mp4 Media Player
  Player? _mediaPlayer;
  VideoController? _mediaController;

  // Youtube Player
  YoutubePlayerController? _youtubeController;
  bool _youtubeReadyFired = false;

  bool get isYoutube => widget.video.sourceType == 'youtube';

  @override
  void initState() {
    super.initState();
    final shouldPlay = widget.isActive && !widget.isDistracted;

    if (isYoutube) {
      final videoId = _extractYoutubeId(widget.video.videoUrl) ?? '';
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: shouldPlay,
          loop: true,
          mute: false,
          hideControls: true,
          disableDragSeek: true,
          controlsVisibleAtStart: false,
          forceHD: false,
        ),
      );
      // Listener ile hazır olduğunda play() komutu gönder
      _youtubeController!.addListener(_onYoutubeControllerUpdate);
    } else {
      _mediaPlayer = Player();
      _mediaController = VideoController(_mediaPlayer!);
      _mediaPlayer!.setPlaylistMode(PlaylistMode.loop);
      _mediaPlayer!.open(Media(widget.video.videoUrl), play: shouldPlay);
    }
  }

  // Hem standart YouTube hem de Shorts linklerinden ID çıkarır
  String? _extractYoutubeId(String url) {
    if (url.contains('/shorts/')) {
      return url.split('/shorts/').last.split('?').first;
    }
    return YoutubePlayer.convertUrlToId(url);
  }

  // Player hazır olduğunda play() komutunu zorla gönder
  void _onYoutubeControllerUpdate() {
    if (_youtubeController == null || _youtubeReadyFired) return;
    if (_youtubeController!.value.isReady) {
      _youtubeReadyFired = true;
      _youtubeController!.removeListener(_onYoutubeControllerUpdate);
      Future.microtask(() => _youtubeController?.play());
    }
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final shouldPlay = widget.isActive && !widget.isDistracted;
    final wasPlaying = oldWidget.isActive && !oldWidget.isDistracted;

    if (shouldPlay != wasPlaying) {
      if (shouldPlay) {
        _mediaPlayer?.play();
        _youtubeController?.play();
      } else {
        _mediaPlayer?.pause();
        _youtubeController?.pause();
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.removeListener(_onYoutubeControllerUpdate);
    _mediaPlayer?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Arka Plan Video Katmanı
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: isYoutube && _youtubeController != null
                ? YoutubePlayerBuilder(
                    player: YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: false,
                      progressColors: const ProgressBarColors(
                        playedColor: Colors.transparent,
                        handleColor: Colors.transparent,
                      ),
                      onReady: () {
                        // onReady garantisi: player iFrame'i hazır
                        Future.microtask(() => _youtubeController?.play());
                      },
                    ),
                    builder: (context, player) {
                      return Transform.scale(
                        scale:
                            1.5, // Siyah kenarlıkları ve YouTube UI'ını ekran dışına it
                        child: player,
                      );
                    },
                  )
                : _mediaController != null
                ? Video(
                    controller: _mediaController!,
                    fit: BoxFit.cover,
                    controls: NoVideoControls,
                  )
                : const SizedBox(),
          ),
        ),

        // 2. Siyah Gradient (Alttan ortaya doğru silikleşen)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            ),
          ),
        ),

        // 3. Sol Üst: Ateş (Streak) Rozeti
        Positioned(
          top: 110,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 18,
                ),
                SizedBox(width: 4),
                Text(
                  '12 Gün',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 4. Sağ Alt: Etkileşim İkonları
        Positioned(
          right: 16,
          bottom: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _AnimatedIconButton(
                icon: Icons.favorite,
                label: '12K',
                iconColor: Colors.redAccent,
              ),
              SizedBox(height: 24),
              _AnimatedIconButton(icon: Icons.chat_bubble, label: '340'),
              SizedBox(height: 24),
              _AnimatedIconButton(icon: Icons.bookmark, label: '1.2K'),
            ],
          ),
        ),

        // 5. Sol Alt: Gramer ve Seviye Metinleri
        Positioned(
          left: 16,
          bottom: 40,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gramer: ${widget.video.grammarTopic}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.difficultyLevel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Tıklama anında zıplama (scale) efekti veren özel İkon Butonu
class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _AnimatedIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor = Colors.white,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.75 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            Icon(widget.icon, color: widget.iconColor, size: 38),
            const SizedBox(height: 6),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
