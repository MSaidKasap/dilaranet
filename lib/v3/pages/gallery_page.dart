import 'package:flutter/material.dart';

import '../data/api.dart';
import '../theme.dart';
import 'posts_list_page.dart';

/// v2 çekmecesindeki "Fotoğraf ve Video Galerisi" alt menüsünün v3 karşılığı.
class V3GalleryPage extends StatelessWidget {
  const V3GalleryPage({super.key});

  static const _items = <({IconData icon, String title, int categoryId})>[
    (
      icon: Icons.photo_library_rounded,
      title: 'Fotoğraf Galerisi',
      categoryId: 7,
    ),
    (
      icon: Icons.forum_rounded,
      title: 'Hasbihal Programı',
      categoryId: 14,
    ),
    (
      icon: Icons.groups_rounded,
      title: 'Hatme-i Hâcegan Sohbetleri',
      categoryId: 13,
    ),
    (
      icon: Icons.people_alt_rounded,
      title: "Talebeleri Üstad'ı Anlatıyor",
      categoryId: 22,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fotoğraf ve Video Galerisi')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Material(
            color: V3Colors.surface,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: Icon(item.icon, color: V3Colors.primary),
              title: Text(item.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing:
                  Icon(Icons.chevron_right, color: V3Colors.textMuted),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => V3PostsListPage(
                    title: item.title,
                    future: V3Api.byCategory(item.categoryId),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
