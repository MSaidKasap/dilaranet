import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../theme.dart';

/// Yazı içeriğindeki YouTube `<iframe>` gömmelerini oynatır.
///
/// `flutter_widget_from_html`'in varsayılan iframe işleyicisi (fwfh_webview)
/// YouTube'un embed sayfasını çıplak bir WebView içinde açıyor; bu da
/// YouTube'un kendi tarafında "video oynatıcı yapılandırma hatası" ekranına
/// düşüyordu. Bunun yerine resmi IFrame Player API'sini doğru şekilde
/// başlatan `youtube_player_iframe` kullanılır.
class V3YoutubeEmbed extends StatefulWidget {
  final String videoId;
  const V3YoutubeEmbed({super.key, required this.videoId});

  /// `src` bir YouTube adresiyse video id'sini döndürür, değilse null.
  static String? videoIdFromUrl(String url) =>
      YoutubePlayerController.convertUrlToId(url);

  @override
  State<V3YoutubeEmbed> createState() => _V3YoutubeEmbedState();
}

class _V3YoutubeEmbedState extends State<V3YoutubeEmbed> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(
          controller: _controller,
          backgroundColor: V3Colors.surface,
        ),
      ),
    );
  }
}
