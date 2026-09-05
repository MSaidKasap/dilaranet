import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/chatbot/chat_screen.dart' show ChatScreen;
import '../../core/pages/about_page.dart' show AboutPage;
import '../data/api.dart';
import '../data/market_api.dart';
import '../data/market_auth.dart';
import '../data/market_models.dart';
import '../theme.dart';
import 'article_page.dart';
import 'bookmarks_page.dart';
import 'books_page.dart';
import 'gallery_page.dart';
import 'market/address_list_page.dart';
import 'market/cart_page.dart';
import 'market/login_page.dart';
import 'market/order_history_page.dart';
import 'notifications_page.dart';
import 'posts_list_page.dart';
import 'prayer_page.dart';
import 'qibla_page.dart';

class V3ProfilePage extends StatelessWidget {
  const V3ProfilePage({super.key});

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _push(BuildContext context, Widget page, {String? title}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => title == null
          ? page
          : Scaffold(
              appBar: AppBar(title: Text(title)),
              body: page,
            ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        ValueListenableBuilder<MarketCustomer?>(
          valueListenable: MarketAuth.instance.customer,
          builder: (context, customer, _) {
            return Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: V3Colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline,
                        size: 40, color: V3Colors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Text(customer?.fullName ?? 'Dilara',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(customer?.email ?? 'dilara.net',
                      style: const TextStyle(color: V3Colors.textMuted)),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        _section('Market'),
        ValueListenableBuilder<MarketCustomer?>(
          valueListenable: MarketAuth.instance.customer,
          builder: (context, customer, _) {
            final loggedIn = MarketAuth.instance.isLoggedIn;
            return Column(
              children: [
                _tile(Icons.shopping_cart_outlined, 'Sepetim', () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MarketCartPage()),
                  );
                }),
                _tile(Icons.location_on_outlined, 'Teslimat & Fatura Adresi',
                    () async {
                  if (!loggedIn) {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const MarketLoginPage()),
                    );
                    if (ok != true || !context.mounted) return;
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddressListPage()),
                  );
                }),
                _tile(Icons.receipt_long_outlined, 'Siparişlerim', () async {
                  if (!loggedIn) {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const MarketLoginPage()),
                    );
                    if (ok != true || !context.mounted) return;
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MarketOrderHistoryPage()),
                  );
                }),
                if (loggedIn)
                  _tile(Icons.logout, 'Çıkış Yap', () => MarketApi.instance.logout())
                else
                  _tile(Icons.login, 'Giriş Yap / Üye Ol', () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MarketLoginPage()),
                    );
                  }),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _tile(Icons.menu_book_outlined, 'Kitaplar',
            () => _push(context, const V3BooksPage())),
        const SizedBox(height: 16),
        _section('Uygulama'),
        _tile(Icons.bookmark_border, 'Yer İmleri',
            () => _push(context, const V3BookmarksPage(), title: 'Yer İmleri')),
        _tile(Icons.access_time, 'Namaz Vakitleri',
            () => _push(context, const V3PrayerPage(), title: 'Namaz Vakitleri')),
        _tile(Icons.explore_outlined, 'Kıble Pusula',
            () => _push(context, const V3QiblaPage(), title: 'Kıble')),
        _tile(Icons.notifications_none_rounded, 'Bildirim Ayarları',
            () => _push(context, const V3NotificationsPage())),
        const SizedBox(height: 16),
        _section('Üstadımız'),
        _tile(Icons.info_outline, 'Hakkında',
            () => _push(context, const AboutPage())),
        _tile(Icons.history_rounded, 'Tarihçe-i Hayatı', () => _push(
            context, const V3ArticlePage(postId: 47))),
        _tile(Icons.description_outlined, 'Vasiyeti',
            () => _push(context, const V3ArticlePage(postId: 49))),
        _tile(Icons.library_books_outlined, 'Eserleri', () => _push(
            context,
            V3PostsListPage(
                title: 'Eserleri', future: V3Api.byCategory(16)))),
        const SizedBox(height: 16),
        _section('İçerikler'),
        _tile(Icons.account_tree_outlined, 'Nakşibendî Müceddidî Silsilesi',
            () => _push(context, const V3ArticlePage(postId: 117))),
        _tile(Icons.article_outlined, 'Köşe Yazıları', () => _push(
            context,
            V3PostsListPage(
                title: 'Köşe Yazıları', future: V3Api.byCategory(9)))),
        _tile(Icons.quiz_outlined, 'Sorular ve Cevaplar', () => _push(
            context,
            V3PostsListPage(
                title: 'Sorular ve Cevaplar',
                future: V3Api.byCategory(12)))),
        _tile(Icons.collections_outlined, 'Fotoğraf ve Video Galerisi',
            () => _push(context, const V3GalleryPage())),
        _tile(Icons.chat_bubble_outline, 'Soru-Cevap Botu',
            () => _push(context, const ChatScreen())),
        const SizedBox(height: 16),
        _section('Dilara'),
        _tile(Icons.language, 'Web sitesi', () => _open('https://www.dilara.net')),
        _tile(Icons.menu_book_outlined, 'Dilara Yayınları',
            () => _open('https://www.dilara.net')),
        _tile(Icons.mail_outline, 'İletişim',
            () => _open('https://www.dilara.net/iletisim')),
        _tile(Icons.privacy_tip_outlined, 'Gizlilik Politikası',
            () => _open('https://www.dilara.net/gizlilik-politikasi')),
      ],
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4, top: 4),
        child: Text(label,
            style: const TextStyle(
                color: V3Colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      );

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: V3Colors.textPrimary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: V3Colors.textMuted),
      onTap: onTap,
    );
  }
}
