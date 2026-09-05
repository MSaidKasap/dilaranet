import 'package:html_character_entities/html_character_entities.dart';
import 'package:intl/intl.dart';

/// WordPress REST (`wp/v2/posts`) kaydının V3 arayüzü için sadeleştirilmiş modeli.
class V3Post {
  final int id;
  final String title;
  final String excerpt;
  final String contentHtml;
  final String imageUrl;
  final DateTime? date;
  final List<int> categoryIds;

  const V3Post({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.contentHtml,
    required this.imageUrl,
    required this.date,
    required this.categoryIds,
  });

  factory V3Post.fromJson(Map<String, dynamic> json) {
    return V3Post(
      id: json['id'] ?? 0,
      title: _plainText(json['title']?['rendered'] ?? ''),
      excerpt: _plainText(json['excerpt']?['rendered'] ?? ''),
      contentHtml: json['content']?['rendered'] ?? '',
      imageUrl: (json['jetpack_featured_media_url'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      categoryIds: ((json['categories'] as List?) ?? const [])
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e != 0)
          .toList(),
    );
  }

  bool get hasImage => imageUrl.startsWith('http');

  /// "20 dk önce" / "3 saat önce" / "2 gün önce" biçiminde göreli zaman.
  String get relativeTime {
    final d = date;
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return DateFormat('d MMM yyyy', 'tr_TR').format(d);
  }

  String get formattedDate {
    final d = date;
    if (d == null) return '';
    return DateFormat('d MMMM yyyy', 'tr_TR').format(d);
  }
}

String _plainText(String html) {
  final withoutTags = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
  final decoded = HtmlCharacterEntities.decode(withoutTags);
  return decoded.replaceAll(RegExp(r'\s+'), ' ').trim();
}
