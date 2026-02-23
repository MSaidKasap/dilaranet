import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/book/book1.dart';
import '../pages/book/book2.dart';
import '../pages/book/book3.dart';
import '../pages/category_posts_page.dart';
import '../pages/html/dilaranet.dart';
import '../pages/html/dilarayayinlari.dart';
import '../pages/post_detail_page.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  Map<String, bool> _expandedStates = {};

  void _onTileTap() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Column(
            children: [
              // Basitleştirilmiş Header
              _buildSimpleHeader(context, isDark),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  physics: const ClampingScrollPhysics(),
                  children: [
                    const SizedBox(height: 16),

                    // Kitaplık
                    _buildExpansionTile(
                      context,
                      icon: Icons.auto_stories_rounded,
                      title: "Kitaplık",
                      color: const Color(0xFF6366F1),
                      children: [
                        _buildSubMenuItem(
                          context,
                          "Sevgi Bağı (Hizb-i A'zam Sesli)",
                          Icons.headphones_rounded,
                          () => _navigateToPage(context, const ContentPage()),
                        ),
                        _buildSubMenuItem(
                          context,
                          "Size Sözüm Öz İnci Armağan",
                          Icons.music_note_rounded,
                          () => _navigateToPage(context, const ContentPage3()),
                        ),
                        _buildSubMenuItem(
                          context,
                          "Âmentü",
                          Icons.menu_book_rounded,
                          () => _navigateToPage(context, const ContentPage2()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Nakşibendî Silsilesi
                    _buildListTile(
                      context,
                      icon: Icons.account_tree_rounded,
                      title: 'Nakşibendî Müceddidî Silsilesi',
                      color: const Color(0xFF06B6D4),
                      onTap: () => _navigateToPage(
                        context,
                        const PostDetail(postId: 117),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Üstadımız
                    _buildExpansionTile(
                      context,
                      icon: Icons.person_rounded,
                      title: "Üstadımız",
                      color: const Color(0xFF8B5CF6),
                      children: [
                        _buildSubMenuItem(
                          context,
                          "Tarihçe-i Hayatı",
                          Icons.history_rounded,
                          () => _navigateToPage(
                            context,
                            const PostDetail(postId: 47),
                          ),
                        ),
                        _buildSubMenuItem(
                          context,
                          "Vasiyeti",
                          Icons.description_rounded,
                          () => _navigateToPage(
                            context,
                            const PostDetail(postId: 49),
                          ),
                        ),
                        _buildSubMenuItem(
                          context,
                          "Eserleri",
                          Icons.library_books_rounded,
                          () => _navigateToPage(
                            context,
                            const CategoryPostsPage(categoryId: 16),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Galeri
                    _buildExpansionTile(
                      context,
                      icon: Icons.collections_rounded,
                      title: "Fotoğraf ve Video Galerisi",
                      color: const Color(0xFFEF4444),
                      children: [
                        _buildSubMenuItem(
                          context,
                          "Fotoğraf Galerisi",
                          Icons.photo_library_rounded,
                          () => _navigateToPage(
                            context,
                            const CategoryPostsPage(categoryId: 7),
                          ),
                        ),
                        _buildVideoExpansion(context),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Sorular ve Cevaplar
                    _buildExpansionTile(
                      context,
                      icon: Icons.quiz_rounded,
                      title: "Sorular ve Cevaplar",
                      color: const Color(0xFF10B981),
                      children: [
                        _buildSubMenuItem(
                          context,
                          "Sorular ve Cevaplar",
                          Icons.question_answer_rounded,
                          () => _navigateToPage(
                            context,
                            const CategoryPostsPage(categoryId: 12),
                          ),
                        ),
                        _buildSubMenuItem(
                          context,
                          "Soru Sor",
                          Icons.add_comment_rounded,
                          () => _navigateToPage(context, const Question()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Köşe Yazıları
                    _buildListTile(
                      context,
                      icon: Icons.article_rounded,
                      title: 'Köşe Yazıları',
                      color: const Color(0xFFF59E0B),
                      onTap: () => _navigateToPage(
                        context,
                        const CategoryPostsPage(categoryId: 9),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Kitap Mağazası
                    _buildListTile(
                      context,
                      icon: Icons.shopping_bag_rounded,
                      title: 'Kitap Mağazası',
                      color: const Color(0xFFEC4899),
                      onTap: () => _navigateToPage(context, const Shop()),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/img/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFF6366F1),
                    size: 32,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Kategoriler ve sayfalar',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _onTileTap();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    final key = title;
    final isExpanded = _expandedStates[key] ?? false;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _onTileTap();
              setState(() {
                _expandedStates[key] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            child: Column(children: children),
          ),
      ],
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _onTileTap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoExpansion(BuildContext context) {
    final key = "video_gallery";
    final isExpanded = _expandedStates[key] ?? false;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _onTileTap();
              setState(() {
                _expandedStates[key] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Icon(
                    Icons.video_library_rounded,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Video Galerisi",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: [
                _buildVideoSubItem(
                  context,
                  "Hasbihal Programı",
                  () => _navigateToPage(
                    context,
                    const CategoryPostsPage(categoryId: 14),
                  ),
                ),
                _buildVideoSubItem(
                  context,
                  "Hatme-i Hâcegan Sohbetleri",
                  () => _navigateToPage(
                    context,
                    const CategoryPostsPage(categoryId: 13),
                  ),
                ),
                _buildVideoSubItem(
                  context,
                  "Talebeleri Üstad'ı anlatıyor",
                  () => _navigateToPage(
                    context,
                    const CategoryPostsPage(categoryId: 22),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVideoSubItem(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _onTileTap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 40),
              Icon(
                Icons.play_circle_outline_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
