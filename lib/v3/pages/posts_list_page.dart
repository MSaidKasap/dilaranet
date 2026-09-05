import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/post.dart';
import '../theme.dart';
import '../widgets/mini_card.dart';
import 'article_page.dart';

/// Tek bir kategori ya da arama sonucu için yazı listesi.
class V3PostsListPage extends StatelessWidget {
  final String title;
  final Future<List<V3Post>> future;

  const V3PostsListPage({
    super.key,
    required this.title,
    required this.future,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<V3Post>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: V3Colors.primary),
            );
          }
          if (snapshot.hasError) {
            return _centered('Bir hata oluştu:\n${snapshot.error}');
          }
          final posts = snapshot.data ?? const [];
          if (posts.isEmpty) {
            return _centered('Bu bölümde henüz yazı yok.');
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
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => V3ArticlePage(post: post),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _centered(String message) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: V3Colors.textMuted),
          ),
        ),
      );
}
