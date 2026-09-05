import 'package:flutter/material.dart';

import '../../core/pages/book/book1.dart' show ContentPage;
import '../../core/pages/book/book2.dart' show ContentPage2;
import '../../core/pages/book/book3.dart' show ContentPage3;

/// v3 kitap kısayolları — eski `lib/core/pages/book/*` ekranlarına açılır,
/// içerik/PDF görüntüleyici mantığı olduğu gibi kullanılır.
class V3Book {
  final String title;
  final String subtitle;
  final String coverAsset;
  final String logoAsset;
  final int pageCount;

  /// 0 tabanlı sayfa indeksinden asset yolu üretir (önbelleğe alma için).
  final String Function(int index) pageAsset;
  final WidgetBuilder open;

  const V3Book({
    required this.title,
    required this.subtitle,
    required this.coverAsset,
    required this.logoAsset,
    required this.pageCount,
    required this.pageAsset,
    required this.open,
  });
}

class V3Books {
  V3Books._();

  static final sevgiBagi = V3Book(
    title: 'Sevgi Bağı',
    subtitle: '224 sayfa · sesli',
    coverAsset: 'assets/img/sevgi (3).jpg',
    logoAsset: 'assets/img/logos.png',
    pageCount: 224,
    pageAsset: (i) => 'assets/img/sevgi (${i + 3}).jpg',
    open: (_) => const ContentPage(),
  );

  static final amentuSerhi = V3Book(
    title: 'Âmentü Şerhi',
    subtitle: '42 sayfa',
    coverAsset: 'assets/img/amnt/logo.png',
    logoAsset: 'assets/img/amnt/logo.png',
    pageCount: 42,
    pageAsset: (i) => 'assets/img/amnt/${i + 3}.jpg',
    open: (_) => const ContentPage2(),
  );

  static final sizeSozum = V3Book(
    title: 'Size Sözüm',
    subtitle: 'Öz İnci Armağan · 295 sayfa · sesli',
    coverAsset: 'assets/img/size/3.jpg',
    logoAsset: 'assets/img/size/size.png',
    pageCount: 295,
    pageAsset: (i) => 'assets/img/size/${i + 3}.jpg',
    open: (_) => const ContentPage3(),
  );

  /// Tüm kitaplar — ana sayfadaki kısayollar ve Profil > Kitaplar sayfası.
  static final all = <V3Book>[sevgiBagi, amentuSerhi, sizeSozum];
}
