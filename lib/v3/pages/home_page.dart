import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/books.dart';
import '../data/post.dart';
import '../theme.dart';
import '../widgets/book_card.dart';
import '../widgets/mini_card.dart';
import '../widgets/network_image.dart';
import 'article_page.dart';

/// v2'deki ana sayfa düzeni: üstte slider, altında kategori çubuğu + popüler/son yazılar.
class V3HomePage extends StatefulWidget {
  const V3HomePage({super.key});

  @override
  State<V3HomePage> createState() => _V3HomePageState();
}

class _V3HomePageState extends State<V3HomePage> {
  late Future<List<V3Post>> _sliderFuture;
  late Future<List<V3Category>> _categoriesFuture;
  Future<List<V3Post>>? _lowerFuture;
  int _selectedCat = 0; // 0 = Tümü (popüler)
  List<V3Category> _categories = const [];

  @override
  void initState() {
    super.initState();
    _sliderFuture = V3Api.latest();
    _lowerFuture = V3Api.popular();
    _categoriesFuture = V3Api.categories();
  }

  Future<void> _refresh() async {
    setState(() {
      _sliderFuture = V3Api.latest();
      _lowerFuture =
          _selectedCat == 0 ? V3Api.popular() : _lowerFuture; // yeniden çek
      _categoriesFuture = V3Api.categories();
    });
    _selectCategory(_selectedCat, force: true);
    await Future.wait([_sliderFuture, if (_lowerFuture != null) _lowerFuture!]);
  }

  void _selectCategory(int index, {bool force = false}) {
    if (index == _selectedCat && !force) return;
    setState(() {
      _selectedCat = index;
      if (index == 0) {
        _lowerFuture = V3Api.popular();
      } else {
        final cat = _categories[index - 1];
        _lowerFuture = V3Api.byCategory(cat.id);
      }
    });
  }

  void _open(V3Post post) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => V3ArticlePage(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: V3Colors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _slider(),
          const SizedBox(height: 8),
          _categoryBar(),
          const SizedBox(height: 16),
          _bookShortcuts(),
          const SizedBox(height: 4),
          _sectionHeader(),
          _lowerList(),
        ],
      ),
    );
  }

  // ---- Slider ----
  Widget _slider() {
    return FutureBuilder<List<V3Post>>(
      future: _sliderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 210,
            child: Center(child: CircularProgressIndicator(color: V3Colors.primary)),
          );
        }
        final posts = (snapshot.data ?? const []).take(6).toList();
        if (posts.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('İçerik yüklenemedi. Bağlantınızı kontrol edin.',
                  style: TextStyle(color: V3Colors.textMuted)),
            ),
          );
        }
        return CarouselSlider.builder(
          itemCount: posts.length,
          itemBuilder: (context, index, realIndex) {
            final post = posts[index];
            return GestureDetector(
              onTap: () => _open(post),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    V3NetworkImage(
                      url: post.imageUrl,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: V3Colors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('YENİ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            height: 210,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.easeInOutCubic,
          ),
        );
      },
    );
  }

  // ---- Kategori çubuğu ----
  Widget _categoryBar() {
    return FutureBuilder<List<V3Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        _categories = snapshot.data ?? const [];
        final labels = ['Tümü', ..._categories.map((c) => c.name)];
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: labels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == _selectedCat;
              return GestureDetector(
                onTap: () => _selectCategory(index),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? V3Colors.primary : V3Colors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: selected ? Colors.white : V3Colors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---- Kitap kısayolları (eskiden Bölümler'deki tüm kitaplar, artık burada) ----
  Widget _bookShortcuts() {
    final books = V3Books.all;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < books.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: V3BookShortcut(book: books[i], compact: true)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader() {
    final title = _selectedCat == 0
        ? 'Popüler'
        : (_selectedCat - 1 < _categories.length
            ? _categories[_selectedCat - 1].name
            : 'İçerikler');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: V3Colors.primary, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: V3Colors.primary)),
        ],
      ),
    );
  }

  // ---- Alt liste (popüler / kategori) ----
  Widget _lowerList() {
    return FutureBuilder<List<V3Post>>(
      future: _lowerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(color: V3Colors.primary)),
          );
        }
        final posts = snapshot.data ?? const [];
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
                child: Text('İçerik bulunamadı.',
                    style: TextStyle(color: V3Colors.textMuted))),
          );
        }
        return Column(
          children: [
            for (final post in posts.take(8)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: V3MiniCard(
                  post: post,
                  categoryLabel: V3Api.labelFor(post.categoryIds),
                  onTap: () => _open(post),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
