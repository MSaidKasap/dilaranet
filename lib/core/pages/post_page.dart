import 'package:Dilara/core/home/screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PostDetailPage extends StatefulWidget {
  final dynamic post;

  const PostDetailPage(this.post, {Key? key}) : super(key: key);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<String> youtubeVideoIds = [];

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _extractYoutubeVideos();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _extractYoutubeVideos() {
    final content = widget.post['content']['rendered'] ?? '';

    // YouTube video ID'lerini çıkar
    final youtubeRegex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );

    final matches = youtubeRegex.allMatches(content);
    youtubeVideoIds = matches.map((match) => match.group(1)!).toList();
  }

  void _checkIfFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isFavorite = prefs.getBool(widget.post['id'].toString()) ?? false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String postId = widget.post['id'].toString();

    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      prefs.setBool(postId, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Okuma listesine eklendi'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      prefs.remove(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Okuma listesinden çıkarıldı'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _sharePost() async {
    try {
      String cleanedContent = HtmlCharacterEntities.decode(
        widget.post['content']['rendered'].replaceAll(RegExp(r'<[^>]*>'), ''),
      );

      await Share.share(
        '${widget.post['title']['rendered']}\n\n$cleanedContent',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Paylaşım hatası oluştu'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String _cleanContentForDisplay(String content) {
    // YouTube iframe'lerini kaldır
    content = content.replaceAll(
      RegExp(
        r'<iframe[^>]*youtube\.com[^>]*>.*?<\/iframe>',
        caseSensitive: false,
        multiLine: true,
      ),
      '',
    );

    // Boş figure taglerini temizle
    content = content.replaceAll(
      RegExp(r'<figure[^>]*>\s*<\/figure>', multiLine: true),
      '',
    );

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final rawContent = (widget.post['content']?['rendered'] ?? '').toString();
    final cleanedContent = _cleanContentForDisplay(rawContent);
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF4F5F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : null,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: _sharePost,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: HtmlWidget(
                      widget.post['title']['rendered'],
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // YouTube Videolar
                  if (youtubeVideoIds.isNotEmpty)
                    ...youtubeVideoIds.map(
                      (videoId) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildYoutubePlayer(videoId, isDark),
                      ),
                    ),

                  // İçerik
                  if (_hasRealHtmlContent(cleanedContent))
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.3 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: HtmlWidget(
                        cleanedContent,
                        textStyle: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoutubePlayer(String videoId, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayerWidget(videoId: videoId),
        ),
      ),
    );
  }
}

bool _hasRealHtmlContent(String html) {
  // ✅ Galeri / resim var mı? (img varsa içerik var say)
  final hasImage = RegExp(r'<img\b', caseSensitive: false).hasMatch(html);
  if (hasImage) return true;

  // script/style temizle
  var s = html
      .replaceAll(
        RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false),
        '',
      )
      .replaceAll(
        RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false),
        '',
      );

  // tüm tag'leri kaldır
  s = s.replaceAll(RegExp(r'<[^>]+>'), '');

  // entity decode
  s = HtmlCharacterEntities.decode(s);

  // boşluk temizle
  s = s.replaceAll('\u00A0', '').trim();

  return s.isNotEmpty;
}

// YouTube Player Widget
class YoutubePlayerWidget extends StatefulWidget {
  final String videoId;

  const YoutubePlayerWidget({Key? key, required this.videoId})
    : super(key: key);

  @override
  State<YoutubePlayerWidget> createState() => _YoutubePlayerWidgetState();
}

class _YoutubePlayerWidgetState extends State<YoutubePlayerWidget> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        loop: false,
        hideControls: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      showVideoProgressIndicator: true,
      progressIndicatorColor: Colors.red,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
      ),
      onReady: () {
        // Video hazır
      },
      onEnded: (data) {
        // Video bitti
      },
    );
  }
}

// Favorite Posts Page
class FavoritePostsPage extends StatelessWidget {
  final List<dynamic> favoritePosts;

  const FavoritePostsPage({Key? key, required this.favoritePosts})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF4F5F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            }
          },
        ),
        title: const Text(
          'Okuma Listesi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: favoritePosts.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: favoritePosts.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PostDetailPage(favoritePosts[index]),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Görsel
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2C2C2C)
                                      : Colors.grey[100],
                                ),
                                child:
                                    favoritePosts[index]['jetpack_featured_media_url'] !=
                                        null
                                    ? Image.network(
                                        favoritePosts[index]['jetpack_featured_media_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image_not_supported,
                                                color: isDark
                                                    ? Colors.white24
                                                    : Colors.grey[400],
                                                size: 32,
                                              );
                                            },
                                      )
                                    : Icon(
                                        Icons.article,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.grey[600],
                                        size: 32,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Başlık
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  HtmlWidget(
                                    (favoritePosts[index]['title']['rendered']
                                                .length >
                                            50)
                                        ? '${favoritePosts[index]['title']['rendered'].substring(0, 50)}...'
                                        : favoritePosts[index]['title']['rendered'],
                                    textStyle: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.favorite,
                                        size: 14,
                                        color: Colors.red.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Okuma listesinde',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.grey[600],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // İkon
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: isDark ? Colors.white24 : Colors.grey[400],
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 60,
              color: isDark ? Colors.white24 : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Henüz favori yazınız yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Beğendiğiniz yazıları favorilere ekleyerek\nburada görebilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
