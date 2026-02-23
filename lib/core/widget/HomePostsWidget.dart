import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utill/app_constants.dart';
import '../pages/book/book1.dart';
import '../pages/book/book3.dart';
import '../pages/post_page.dart';
import '../../utill/database_helper.dart';

class HomePostsWidget extends StatefulWidget {
  const HomePostsWidget({Key? key}) : super(key: key);

  @override
  _HomePostsWidgetState createState() => _HomePostsWidgetState();
}

class _HomePostsWidgetState extends State<HomePostsWidget> {
  int _selectedCategoryIndex = 0;
  List<dynamic> categories = [];
  bool isLoadingCategories = true;

  List<dynamic>? _cachedSliderPosts;
  bool _isLoadingSlider = true;

  Map<int, List<dynamic>> _postCache = {};

  @override
  void initState() {
    super.initState();
    fetchCategories();
    _loadSliderPosts();
  }

  Future<void> _loadSliderPosts() async {
    try {
      final posts = await fetchLatestPosts();
      if (mounted) {
        setState(() {
          _cachedSliderPosts = posts;
          _isLoadingSlider = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSlider = false;
        });
      }
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://dilara.net/wp-json/mobil-app/v1/settings'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> settingsData = json.decode(response.body);
        final List<dynamic> visibleCategories =
            settingsData['visible_categories'] ?? [];

        final List<Map<String, dynamic>> allCategories = [
          {'id': 0, 'name': 'Hepsi', 'slug': 'hepsi'},
        ];

        for (var cat in visibleCategories) {
          allCategories.add({
            'id': cat['id'] ?? 0,
            'name': cat['name'] ?? '',
            'slug': cat['slug'] ?? '',
          });
        }

        if (mounted) {
          setState(() {
            categories = allCategories;
            isLoadingCategories = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            categories = [
              {'id': 0, 'name': 'Hepsi', 'slug': 'hepsi'},
            ];
            isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          categories = [
            {'id': 0, 'name': 'Hepsi', 'slug': 'hepsi'},
          ];
          isLoadingCategories = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 10)),

          // Slider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildSliderSection(isDark),
            ),
          ),

          // Audio Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: _audioCardsRow(context, isDark),
            ),
          ),

          // Kategori Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildCategorySelectorModern(isDark),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Post Listesi
          _buildSliverPostList(isDark),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSliderSection(bool isDark) {
    if (_isLoadingSlider) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      );
    }

    if (_cachedSliderPosts == null || _cachedSliderPosts!.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSlider(_cachedSliderPosts!);
  }

  Widget _buildSlider(List posts) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CarouselSlider.builder(
          itemCount: posts.length,
          itemBuilder: (context, index, realIndex) {
            final post = posts[index];
            final imageUrl = post['jetpack_featured_media_url'];
            String rawTitle = post['title']['rendered'] ?? '';
            final title = rawTitle.length > 80
                ? '${rawTitle.substring(0, 80)}...'
                : rawTitle;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PostDetailPage(post)),
                );
              },
              child: Container(
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Html(
                        data: title,
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            color: Colors.white,
                            fontSize: FontSize(15),
                            fontWeight: FontWeight.w700,
                            maxLines: 2,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          options: CarouselOptions(
            autoPlayCurve: Curves.easeInOutCubic,
            viewportFraction: 1,
            enlargeCenterPage: false,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            height: 180,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelectorModern(bool isDark) {
    if (isLoadingCategories) {
      return const SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          final rawName = (categories[index]['name'] ?? '').toString();
          final categoryName = rawName.toLowerCase() == 'all'
              ? 'Hepsi'
              : rawName;

          return GestureDetector(
            onTap: () {
              if (_selectedCategoryIndex != index) {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  categoryName,
                  style: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _audioCardsRow(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _softNavTile(
            title: "Sevgi\nBağı",
            imagePath: 'assets/img/logos.png',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContentPage()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _softNavTile(
            title: "Size Sözüm\nÖz İnci Armağan",
            imagePath: 'assets/img/size/size.png',
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContentPage3()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _softNavTile({
    required String title,
    required String imagePath,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported_outlined,
                        color: isDark ? Colors.white54 : Colors.black54,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverPostList(bool isDark) {
    final selectedCategoryId = _selectedCategoryIndex == 0
        ? 0
        : categories[_selectedCategoryIndex]['id'];

    if (_postCache.containsKey(selectedCategoryId)) {
      return _buildPostListSliver(_postCache[selectedCategoryId]!, isDark);
    }

    return FutureBuilder<List<dynamic>>(
      future: _loadAndCachePosts(selectedCategoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bir hata oluştu',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'İçerik bulunamadı',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildPostListSliver(snapshot.data!, isDark);
      },
    );
  }

  Future<List<dynamic>> _loadAndCachePosts(int categoryId) async {
    List<dynamic> posts;

    if (categoryId == 0) {
      posts = await fetchPostPop();
    } else {
      posts = await fetchPostsByCategory(categoryId);
    }

    _postCache[categoryId] = posts;
    return posts;
  }

  Widget _buildPostListSliver(List<dynamic> posts, bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final post = posts[index];
          final imageUrl = post['jetpack_featured_media_url'];
          final title = post['title']['rendered'];
          final excerpt = post['excerpt']['rendered'];
          final postId = post['id'].toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                  blurRadius: 10,
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
                      builder: (context) => PostDetailPage(post),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl ?? '',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.image_outlined,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey[400],
                                size: 32,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Html(
                              data: title,
                              style: {
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(15),
                                  fontWeight: FontWeight.w600,
                                  maxLines: 2,
                                  textOverflow: TextOverflow.ellipsis,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                ),
                              },
                            ),
                            const SizedBox(height: 6),
                            Html(
                              data: excerpt,
                              style: {
                                "body": Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(13),
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF6B7280),
                                  maxLines: 2,
                                  textOverflow: TextOverflow.ellipsis,
                                  lineHeight: const LineHeight(1.4),
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          FavoriteButton(postId: postId),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }, childCount: posts.length > 20 ? 20 : posts.length),
      ),
    );
  }
}

class FavoriteButton extends StatefulWidget {
  final String postId;
  const FavoriteButton({Key? key, required this.postId}) : super(key: key);

  @override
  _FavoriteButtonState createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isFavorite = prefs.getBool(widget.postId) ?? false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      prefs.setBool(widget.postId, true);
    } else {
      prefs.remove(widget.postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.favorite : Icons.favorite_border,
        size: 20,
      ),
      color: _isFavorite
          ? Colors.red
          : (isDark ? Colors.white38 : Colors.grey[400]),
      onPressed: _toggleFavorite,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

Future<List<dynamic>> fetchPostsByCategory(int categoryId) async {
  try {
    final response = await http.get(
      Uri.parse(
        'https://dilara.net/wp-json/wp/v2/posts?categories=$categoryId&per_page=20',
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}
