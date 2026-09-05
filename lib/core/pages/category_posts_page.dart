import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../utill/app_constants.dart';

class CategoryPostsPage extends StatefulWidget {
  final int categoryId;
  final String? categoryName;

  const CategoryPostsPage({
    Key? key,
    required this.categoryId,
    this.categoryName,
  }) : super(key: key);

  @override
  _CategoryPostsPageState createState() => _CategoryPostsPageState();
}

class _CategoryPostsPageState extends State<CategoryPostsPage>
    with TickerProviderStateMixin {
  List<dynamic> _posts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, bool> _favoriteStates = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMorePosts = true; // Yeni eklendi
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
    _fetchPosts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchPosts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _posts.clear();
        _isLoading = true;
        _hasError = false;
        _hasMorePosts = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$URL$URLPLS/posts?categories=${widget.categoryId}&per_page=20&page=$_currentPage&orderby=date&order=desc',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> newPosts = json.decode(response.body);

        if (mounted) {
          setState(() {
            if (isRefresh) {
              _posts = newPosts;
            } else {
              _posts.addAll(newPosts);
            }
            _isLoading = false;
            _hasError = false;

            // Eğer gelen post sayısı 20'den azsa, daha fazla post yok
            if (newPosts.length < 20) {
              _hasMorePosts = false;
            }
          });

          _checkAllFavorites();
          _animationController.forward();
        }
      } else if (response.statusCode == 400) {
        // Sayfa bulunamadı, daha fazla post yok
        if (mounted) {
          setState(() {
            _hasMorePosts = false;
            _isLoading = false;
            _isLoadingMore = false;
          });
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        // Eğer ilk yükleme değilse, sadece daha fazla post olmadığını belirt
        if (_currentPage > 1) {
          setState(() {
            _hasMorePosts = false;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _fetchPosts();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _checkAllFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, bool> favoriteStates = {};

    for (var post in _posts) {
      String postId = post['id'].toString();
      favoriteStates[postId] = prefs.getBool(postId) ?? false;
    }

    if (mounted) {
      setState(() {
        _favoriteStates = favoriteStates;
      });
    }
  }

  Future<void> _toggleFavorite(dynamic post) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String postId = post['id'].toString();
    bool currentState = _favoriteStates[postId] ?? false;
    bool newState = !currentState;

    setState(() {
      _favoriteStates[postId] = newState;
    });

    if (newState) {
      prefs.setBool(postId, true);
      _showSnackBar('Okuma listesine eklendi', Icons.favorite, Colors.green);
    } else {
      prefs.remove(postId);
      _showSnackBar(
        'Okuma listesinden çıkarıldı',
        Icons.favorite_border,
        Colors.orange,
      );
    }

    HapticFeedback.lightImpact();
  }

  Future<void> _sharePost(dynamic post) async {
    try {
      String cleanedContent = HtmlCharacterEntities.decode(
        post['content']['rendered'].replaceAll(RegExp(r'<[^>]*>'), ''),
      );

      await Share.share('${post['title']['rendered']}\n\n$cleanedContent');
    } catch (e) {
      _showSnackBar('Paylaşım hatası oluştu', Icons.error, Colors.red);
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getCategoryName() {
    if (widget.categoryName != null) return widget.categoryName!;

    switch (widget.categoryId) {
      case 7:
        return 'Fotoğraf Galerisi';
      case 9:
        return 'Köşe Yazıları';
      case 12:
        return 'Sorular ve Cevaplar';
      case 13:
        return 'Hatme-i Hâcegan Sohbetleri';
      case 14:
        return 'Hasbihal Programı';
      case 16:
        return 'Eserleri';
      case 22:
        return 'Talebeleri Üstad\'ı Anlatıyor';
      default:
        return 'Kategoriler';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF4F5F7),
      body: RefreshIndicator(
        onRefresh: () => _fetchPosts(isRefresh: true),
        color: isDark ? Colors.white : Colors.black,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern App Bar
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
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  _getCategoryName(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                centerTitle: true,
              ),
            ),

            // Content
            _isLoading && _posts.isEmpty
                ? _buildLoadingSliver(isDark)
                : _hasError
                ? _buildErrorSliver(isDark)
                : _posts.isEmpty
                ? _buildEmptySliver(isDark)
                : _buildPostsSliver(isDark),

            // Load more indicator
            if (_isLoadingMore)
              SliverToBoxAdapter(child: _buildLoadMoreIndicator(isDark)),

            // End message
            if (!_hasMorePosts && _posts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Tüm içerikler yüklendi',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSliver(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDark ? Colors.white : Colors.black,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İçerik yüklenirken bir sorun oluştu',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _fetchPosts(isRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySliver(bool isDark) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.article_outlined,
                size: 50,
                color: isDark ? Colors.white24 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz içerik yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu kategoride henüz paylaşım bulunmuyor',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsSliver(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildPostCard(_posts[index], index, isDark),
          );
        }, childCount: _posts.length),
      ),
    );
  }

  Widget _buildPostCard(dynamic post, int index, bool isDark) {
    final isFavorite = _favoriteStates[post['id'].toString()] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToPostDetail(post),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2C2C2C)
                          : Colors.grey[100],
                    ),
                    child: post['jetpack_featured_media_url'] != null
                        ? Image.network(
                            post['jetpack_featured_media_url'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
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
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HtmlWidget(
                        post['title']['rendered'],
                        textStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Action buttons
                      Row(
                        children: [
                          _buildActionButton(
                            icon: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite
                                ? Colors.red
                                : (isDark ? Colors.white38 : Colors.grey[400]!),
                            onPressed: () => _toggleFavorite(post),
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.share_rounded,
                            color: isDark ? Colors.white38 : Colors.grey[400]!,
                            onPressed: () => _sharePost(post),
                            isDark: isDark,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: isDark ? Colors.white24 : Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : Colors.black,
          strokeWidth: 2,
        ),
      ),
    );
  }

  void _navigateToPostDetail(dynamic post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PostDetailPage(
          post: post,
          isFavorite: _favoriteStates[post['id'].toString()] ?? false,
          onFavoriteToggle: () => _toggleFavorite(post),
          onShare: () => _sharePost(post),
        ),
      ),
    );
  }
}

class _PostDetailPage extends StatelessWidget {
  final dynamic post;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;

  const _PostDetailPage({
    required this.post,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
                onPressed: onFavoriteToggle,
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: onShare,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                      post['title']['rendered'],
                      textStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                      post['content']['rendered'],
                      textStyle: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
