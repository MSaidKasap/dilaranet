import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/post.dart';
import '../data/prayer.dart';
import '../theme.dart';
import '../widgets/mini_card.dart';
import 'article_page.dart';
import 'prayer_notification_settings_page.dart';

/// Bildirimler ekranı: namaz bildirimi ayarı + son yazılar akışı.
class V3NotificationsPage extends StatefulWidget {
  const V3NotificationsPage({super.key});

  @override
  State<V3NotificationsPage> createState() => _V3NotificationsPageState();
}

class _V3NotificationsPageState extends State<V3NotificationsPage> {
  bool _prayerNotif = false;
  bool _loadingPref = true;
  late Future<List<V3Post>> _recent;

  @override
  void initState() {
    super.initState();
    _recent = V3Api.latest();
    V3PrayerRepository.notificationsEnabled().then((v) {
      if (!mounted) return;
      setState(() {
        _prayerNotif = v;
        _loadingPref = false;
      });
    });
  }

  Future<void> _togglePrayer(bool value) async {
    setState(() => _prayerNotif = value);
    try {
      await V3PrayerRepository.setNotificationsEnabled(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value
              ? 'Namaz vakti bildirimleri açıldı'
              : 'Namaz vakti bildirimleri kapatıldı'),
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _prayerNotif = !value);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ayarlanamadı: ${'$e'.replaceFirst('Exception: ', '')}'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: V3Colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  activeThumbColor: V3Colors.primary,
                  title: const Text('Namaz vakti bildirimleri'),
                  subtitle: const Text('Her vakitten önce hatırlat',
                      style:
                          TextStyle(fontSize: 12, color: V3Colors.textMuted)),
                  value: _prayerNotif,
                  onChanged: _loadingPref ? null : _togglePrayer,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded,
                      color: V3Colors.textPrimary),
                  title: const Text('Vakit Başına Ayarlar'),
                  subtitle: const Text(
                      'Süre, sessiz bildirim ve vakit bazlı açma/kapama',
                      style: TextStyle(fontSize: 12, color: V3Colors.textMuted)),
                  trailing: const Icon(Icons.chevron_right,
                      color: V3Colors.textMuted),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            const V3PrayerNotificationSettingsPage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Son Yazılar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FutureBuilder<List<V3Post>>(
            future: _recent,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: V3Colors.primary)),
                );
              }
              final posts = snapshot.data ?? const [];
              if (posts.isEmpty) {
                return const Text('Şu an gösterilecek bir şey yok.',
                    style: TextStyle(color: V3Colors.textMuted));
              }
              return Column(
                children: [
                  for (final post in posts.take(10)) ...[
                    V3MiniCard(
                      post: post,
                      categoryLabel: V3Api.labelFor(post.categoryIds),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => V3ArticlePage(post: post),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
