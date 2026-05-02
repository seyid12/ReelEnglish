import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    // Oynatıcıyı başlat
    player = Player();
    controller = VideoController(player);

    // Videoyu döngüye al
    player.setPlaylistMode(PlaylistMode.loop);

    // Videoyu otomatik başlat
    player.open(Media(widget.url), play: true);
  }

  @override
  void dispose() {
    // Sayfa kaydırıldığında (widget dispose olduğunda) belleği temizle
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      fit: BoxFit.cover,
      controls: NoVideoControls, // Reel tarzı görünüm için kontrolleri gizle
    );
  }
}
