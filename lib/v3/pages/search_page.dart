import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/post.dart';
import '../theme.dart';
import '../widgets/mini_card.dart';
import 'article_page.dart';

class V3SearchPage extends StatefulWidget {
  const V3SearchPage({super.key});

  @override
  State<V3SearchPage> createState() => _V3SearchPageState();
}

class _V3SearchPageState extends State<V3SearchPage> {
  final _controller = TextEditingController();
  Future<List<V3Post>>? _future;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    final q = _controller.text.trim();
    if (q.isEmpty || q == _lastQuery) return;
    setState(() {
      _lastQuery = q;
      _future = V3Api.search(q);
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ara')),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: V3Colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: V3Colors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _run(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Yazılarda ara...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _run,
                  icon: const Icon(Icons.arrow_forward, color: V3Colors.primary),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _future == null
              ? Center(
                  child: Text('Bir kelime yazıp arayın.',
                      style: TextStyle(color: V3Colors.textMuted)),
                )
              : FutureBuilder<List<V3Post>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: V3Colors.primary),
                      );
                    }
                    final posts = snapshot.data ?? const [];
                    if (posts.isEmpty) {
                      return Center(
                        child: Text('"$_lastQuery" için sonuç bulunamadı.',
                            style: TextStyle(color: V3Colors.textMuted)),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
        ),
      ],
    );
  }
}
