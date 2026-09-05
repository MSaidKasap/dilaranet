import 'package:flutter/material.dart';

import 'data/books.dart';
import 'data/market_auth.dart';
import 'pages/shell.dart';
import 'theme.dart';

/// V3 arayüzünün kök widget'ı. Eski `lib/core` yapısına dokunmaz;
/// `main.dart` içinden `home: V3App()` ile devreye girer.
class V3App extends StatelessWidget {
  const V3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dilara',
      theme: V3Theme.light(),
      darkTheme: V3Theme.dark(),
      themeMode: ThemeMode.system,
      home: const V3Splash(),
    );
  }
}

/// Açılış ekranı: kitapların ilk sayfalarını önbelleğe alarak
/// kitapların takılmadan açılmasını sağlar, sonra v3 ana ekranına geçer.
class V3Splash extends StatefulWidget {
  const V3Splash({super.key});

  @override
  State<V3Splash> createState() => _V3SplashState();
}

class _V3SplashState extends State<V3Splash> {
  static const _pagesPerBook = 15;
  static const _minSplash = Duration(milliseconds: 900);
  static const _hardDeadline = Duration(seconds: 8);

  double _progress = 0;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _run() async {
    final started = DateTime.now();
    await MarketAuth.instance.restore();
    await _precacheBooks();
    final elapsed = DateTime.now().difference(started);
    if (elapsed < _minSplash) {
      await Future.delayed(_minSplash - elapsed);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const V3Shell()),
    );
  }

  Future<void> _precacheBooks() async {
    final books = V3Books.all;
    final counts = [
      for (final b in books)
        _pagesPerBook < b.pageCount ? _pagesPerBook : b.pageCount
    ];
    final total = counts.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    final deadline = DateTime.now().add(_hardDeadline);
    var done = 0;
    for (var b = 0; b < books.length; b++) {
      final book = books[b];
      for (var i = 0; i < counts[b]; i++) {
        if (_cancelled || DateTime.now().isAfter(deadline)) return;
        try {
          await precacheImage(AssetImage(book.pageAsset(i)), context);
        } catch (_) {
          // Eksik/okunamayan sayfa: sessizce atla, ilerlemeyi durdurma.
        }
        done++;
        if (mounted) setState(() => _progress = done / total);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/logo.png', width: 260),
            const SizedBox(height: 40),
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress,
                  minHeight: 4,
                  backgroundColor: V3Colors.surface,
                  color: V3Colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Kitaplar hazırlanıyor... %${(_progress * 100).round()}',
              style: TextStyle(color: V3Colors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
