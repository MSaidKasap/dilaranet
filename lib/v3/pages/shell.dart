import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/market_api.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_bar.dart';
import 'categories_page.dart';
import 'home_page.dart';
import 'market/market_home_page.dart';
import 'notifications_page.dart';
import 'prayer_page.dart';
import 'profile_page.dart';
import 'qibla_page.dart';
import 'search_page.dart';

/// news_ui `pages/page_switch.dart` uyarlaması.
/// Sekmeler: Ana Sayfa · Namaz · Kıble · Bölümler · Market · Profil
class V3Shell extends StatefulWidget {
  const V3Shell({super.key});

  @override
  State<V3Shell> createState() => _V3ShellState();
}

class _V3ShellState extends State<V3Shell> {
  int _index = 0;

  static const _titles = [
    'Dilara',
    'Namaz Vakitleri',
    'Kıble',
    'Bölümler',
    'Market',
    'Profil'
  ];

  @override
  void initState() {
    super.initState();
    V3Api.categories(); // kart etiketleri için önden yükle
    MarketApi.instance.cart(); // sepet rozetini önden yükle
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const V3SearchPage()),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const V3NotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Arama yalnızca içerik sekmelerinde (Ana Sayfa, Bölümler) görünsün;
    // Market'in kendi arama/sepet aksiyonları kendi AppBar'ında.
    final showSearch = _index == 0 || _index == 3;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            V3AppBar(
              title: _titles[_index],
              onSearchTap: showSearch ? _openSearch : null,
              onNotificationsTap: _openNotifications,
              // Market sekmesinin kendi başlığında zaten bir sepet ikonu var.
              showCart: _index != 4,
            ),
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  V3HomePage(),
                  V3PrayerPage(),
                  V3QiblaPage(),
                  V3CategoriesPage(),
                  MarketHomePage(),
                  V3ProfilePage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: V3BottomBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}
