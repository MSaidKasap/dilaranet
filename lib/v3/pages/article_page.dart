import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';

import '../data/api.dart';
import '../data/bookmarks.dart';
import '../data/post.dart';
import '../theme.dart';
import '../widgets/network_image.dart';
import '../widgets/youtube_embed.dart';

/// news_ui `pages/single_news_page.dart` + `widgets/single_news_header.dart`
/// uyarlaması — canlı WordPress içeriğiyle.
class V3ArticlePage extends StatefulWidget {
  final V3Post? post;
  final int? postId;

  const V3ArticlePage({super.key, this.post, this.postId})
      : assert(post != null || postId != null);

  @override
  State<V3ArticlePage> createState() => _V3ArticlePageState();
}

class _V3ArticlePageState extends State<V3ArticlePage> {
  V3Post? _post;
  bool _bookmarked = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    if (_post == null) {
      V3Api.postById(widget.postId!).then((p) {
        if (mounted) setState(() => _post = p);
      });
    }
    _loadBookmark();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmark() async {
    final id = _post?.id ?? widget.postId;
    if (id == null) return;
    final saved = await V3Bookmarks.contains(id);
    if (mounted) setState(() => _bookmarked = saved);
  }

  Future<void> _toggleBookmark() async {
    final id = _post?.id;
    if (id == null) return;
    final saved = await V3Bookmarks.toggle(id);
    if (!mounted) return;
    setState(() => _bookmarked = saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? 'Yer imlerine eklendi' : 'Yer imlerinden çıkarıldı'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _share() {
    final post = _post;
    if (post == null) return;
    SharePlus.instance.share(
      ShareParams(text: '${post.title}\n\nhttps://www.dilara.net/?p=${post.id}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(post),
            Expanded(
              child: post == null
                  ? const Center(
                      child: CircularProgressIndicator(color: V3Colors.primary),
                    )
                  : _body(post),
            ),
          ],
        ),
      ),
      bottomNavigationBar: post == null ? null : _commentBar(),
    );
  }

  Widget _header(V3Post? post) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: V3Colors.shadow, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, size: 28),
          ),
          Expanded(
            child: Text(
              post?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: post == null ? null : _toggleBookmark,
            icon: Icon(
              _bookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 22,
              color: _bookmarked ? V3Colors.primary : V3Colors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: post == null ? null : _share,
            icon: const Icon(Icons.share_outlined, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _body(V3Post post) {
    final label = V3Api.labelFor(post.categoryIds);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            post.title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 22, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(post.relativeTime,
                  style: const TextStyle(color: V3Colors.textMuted, fontSize: 13)),
              if ((label ?? '').isNotEmpty) ...[
                const Text('  ·  ',
                    style: TextStyle(color: V3Colors.textMuted, fontSize: 13)),
                Text(label!,
                    style: const TextStyle(
                        color: V3Colors.primary, fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (post.hasImage)
            V3NetworkImage(
              url: post.imageUrl,
              height: V3Size.h(context, 210),
            ),
          if (post.hasImage) const SizedBox(height: 18),
          HtmlWidget(
            post.contentHtml,
            textStyle: const TextStyle(
                fontSize: 16, height: 1.7, color: Color.fromRGBO(60, 64, 78, 1)),
            customWidgetBuilder: (element) {
              if (element.localName != 'iframe') return null;
              final src = element.attributes['src'] ?? '';
              final videoId = V3YoutubeEmbed.videoIdFromUrl(src);
              if (videoId == null) return null;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: V3YoutubeEmbed(videoId: videoId),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _commentBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color.fromRGBO(232, 232, 232, 1)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Yorum yaz...',
                    hintStyle: TextStyle(color: Color.fromRGBO(186, 186, 186, 1)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                _commentController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Yorumlar yakında etkinleşecek'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: V3Colors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Transform.rotate(
                  angle: -0.8,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
