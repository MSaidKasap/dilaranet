import 'package:flutter/material.dart';

import '../data/api.dart';
import '../theme.dart';
import 'posts_list_page.dart';

/// news_ui `pages/category_selection.dart` uyarlaması — canlı kategoriler.
class V3CategoriesPage extends StatefulWidget {
  const V3CategoriesPage({super.key});

  @override
  State<V3CategoriesPage> createState() => _V3CategoriesPageState();
}

class _V3CategoriesPageState extends State<V3CategoriesPage> {
  late Future<List<V3Category>> _future;

  /// dilara.net kategorilerinin adına göre anlamlı ikon seçer.
  /// Anahtar kelime eşleşmezse genel bir kitap ikonuna düşer.
  static IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('video')) return Icons.play_circle_outline;
    if (n.contains('foto') || n.contains('galeri')) {
      return Icons.photo_library_outlined;
    }
    if (n.contains('soru') || n.contains('cevap')) return Icons.help_outline;
    if (n.contains('yazar') || n.contains('yazı') || n.contains('köşe')) {
      return Icons.article_outlined;
    }
    if (n.contains('silsile') || n.contains('nakşibend')) {
      return Icons.account_tree_outlined;
    }
    if (n.contains('talebe') || n.contains('öğrenci')) {
      return Icons.groups_outlined;
    }
    if (n.contains('üstad') || n.contains('hoca')) return Icons.star_outline;
    if (n.contains('vasiyet')) return Icons.assignment_outlined;
    if (n.contains('hasbihal') || n.contains('sohbet')) {
      return Icons.forum_outlined;
    }
    if (n.contains('eser') || n.contains('kitap')) {
      return Icons.menu_book_outlined;
    }
    return Icons.menu_book_outlined;
  }

  @override
  void initState() {
    super.initState();
    _future = V3Api.categories();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<V3Category>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: V3Colors.primary),
          );
        }
        final categories = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text(
              'İlgilendiğin bölümü seç.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Kategoriler yüklenemedi.',
                      style: TextStyle(color: V3Colors.textMuted)),
                ),
              )
            else
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: categories.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _CategoryTile(
                    label: category.name,
                    icon: _iconFor(category.name),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => V3PostsListPage(
                          title: category.name,
                          future: V3Api.byCategory(category.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: V3Colors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: V3Colors.textPrimary),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
