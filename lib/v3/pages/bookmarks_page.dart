import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/bookmarks.dart';
import '../data/post.dart';
import '../theme.dart';
import '../widgets/mini_card.dart';
import 'article_page.dart';

class V3BookmarksPage extends StatefulWidget {
  const V3BookmarksPage({super.key});

  @override
  State<V3BookmarksPage> createState() => _V3BookmarksPageState();
}

class _V3BookmarksPageState extends State<V3BookmarksPage> {
  late Future<List<V3Post>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<V3Post>> _load() async {
    final ids = await V3Bookmarks.ids();
    final posts = <V3Post>[];
    for (final id in ids) {
      final post = await V3Api.postById(id);
      if (post != null) posts.add(post);
    }
    return posts;
  }

  Future<void> _refresh() async {
    final fresh = _load();
    setState(() {
      _future = fresh;
    });
    await fresh;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: V3Colors.primary,
      onRefresh: _refresh,
      child: FutureBuilder<List<V3Post>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: V3Colors.primary),
            );
          }
          final posts = snapshot.data ?? const [];
          if (posts.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Icon(Icons.bookmark_border,
                    size: 48, color: V3Colors.textMuted),
                const SizedBox(height: 12),
                Center(
                  child: Text('Henüz kaydedilmiş yazı yok.',
                      style: TextStyle(color: V3Colors.textMuted)),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = posts[index];
              return V3MiniCard(
                post: post,
                categoryLabel: V3Api.labelFor(post.categoryIds),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => V3ArticlePage(post: post),
                    ),
                  );
                  _refresh();
                },
              );
            },
          );
        },
      ),
    );
  }
}
