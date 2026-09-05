import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utill/app_constants.dart';
import '../home/screen.dart';
import '../pages/post_page.dart';
import '../pages/settings_page.dart';

class FoterBarWidget extends StatefulWidget {
  const FoterBarWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FoterBarWidgetState createState() => _FoterBarWidgetState();
}

class _FoterBarWidgetState extends State<FoterBarWidget>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Favori gönderilerinizi almak için kullanılacak fonksiyon
  Future<List<dynamic>> _getFavoritePosts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoritePostIds = prefs.getKeys().toList();
    List<dynamic> favoritePosts = [];

    for (String postId in favoritePostIds) {
      if (prefs.getBool(postId) == true) {
        // Her bir favori post için detayları çek
        int? parsedPostId = int.tryParse(postId);
        if (parsedPostId != null) {
          Map<String, dynamic> postDetails = await WPAPIPOST.fetchPosts(
            parsedPostId,
          );

          // Başlık ve içeriği favori postlar listesine ekle
          favoritePosts.add(postDetails);
        }
      }
    }

    return favoritePosts;
  }

  // Favori gönderileri gösteren dialogu açan fonksiyon
  Future<void> _showFavoritesDialog() async {
    // Loading göstergesi

    try {
      List<dynamic> favoritePosts = await _getFavoritePosts();

      // Loading dialog'unu kapat
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      // Favoriler sayfasını aç
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => FavoritePostsPage(favoritePosts: favoritePosts),
        ),
      );
    } catch (e) {
      // Loading dialog'unu kapat
      Navigator.of(context).pop();

      // Hata göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Okuma listesi yüklenirken hata oluştu'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    // Animasyon başlat
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Haptic feedback

    setState(() {
      _selectedIndex = index;
    });

    if (_selectedIndex == 0) {
      // AnaSayfa öğesine tıklanıldığında HomeScreen'e yönlendirme yap
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (_selectedIndex == 1) {
      _showFavoritesDialog();
    } else if (_selectedIndex == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GeneralSettingsPage()),
      ).then((value) {
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainer,
                colorScheme.surfaceContainer.withOpacity(0.8),
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                color: const Color(0xFF6366F1), // Indigo
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.bookmark_rounded,
                label: 'Okuma Listesi',
                color: const Color(0xFF06B6D4), // Cyan
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.settings_rounded,
                label: 'Ayarlar',
                color: const Color(0xFF8B5CF6), // Purple
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? _scaleAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _onItemTapped(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: color.withOpacity(0.3), width: 1)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isSelected
                          ? color
                          : colorScheme.onSurface.withOpacity(0.6),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected
                          ? color
                          : colorScheme.onSurface.withOpacity(0.6),
                      fontSize: isSelected ? 11 : 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Alternatif olarak daha minimalist bir versiyon
class MinimalBottomNav extends StatefulWidget {
  const MinimalBottomNav({Key? key}) : super(key: key);

  @override
  _MinimalBottomNavState createState() => _MinimalBottomNavState();
}

class _MinimalBottomNavState extends State<MinimalBottomNav> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(20),
      height: 60,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMinimalNavItem(0, Icons.home_rounded, const Color(0xFF6366F1)),
          _buildMinimalNavItem(
            1,
            Icons.bookmark_rounded,
            const Color(0xFF06B6D4),
          ),
          _buildMinimalNavItem(
            2,
            Icons.settings_rounded,
            const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalNavItem(int index, IconData icon, Color color) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Burada navigation logic'i eklenecek
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 60 : 40,
        height: isSelected ? 60 : 40,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          size: isSelected ? 24 : 20,
        ),
      ),
    );
  }
}
