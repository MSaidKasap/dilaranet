import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utill/app_constants.dart' show URL, URLPLS;
import 'post.dart';

/// V3 arayüzünün veri kaynağı. dilara.net WordPress REST API'sini kullanır.
/// Eski `app_constants.dart` uç noktalarıyla aynı; sadece V3Post modeline eşler.
class V3Category {
  final int id;
  final String name;
  const V3Category({required this.id, required this.name});
}

class V3Api {
  /// Kategori id -> ad eşlemesi (kart etiketleri için). `categories()` doldurur.
  static final Map<int, String> categoryNames = {};

  /// Bir yazının ilk bilinen kategori adını döndürür.
  static String? labelFor(List<int> ids) {
    for (final id in ids) {
      final name = categoryNames[id];
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  static Uri _wp(String path, [Map<String, String>? query]) =>
      Uri.parse('$URL$URLPLS/$path').replace(queryParameters: query);

  static Future<List<V3Post>> latest({int perPage = 15}) async {
    final res = await http.get(_wp('posts', {'per_page': '$perPage'}));
    return _parseList(res);
  }

  static Future<List<V3Post>> byCategory(int categoryId, {int perPage = 20}) async {
    final res = await http.get(
      _wp('posts', {'categories': '$categoryId', 'per_page': '$perPage'}),
    );
    return _parseList(res);
  }

  /// Popüler yazılar — WordPress Popular Posts eklentisi (v2 ile aynı uç nokta).
  static Future<List<V3Post>> popular({int limit = 10}) async {
    final res = await http.get(Uri.parse(
        '${URL}wp-json/wordpress-popular-posts/v1/popular-posts?range=all&limit=$limit'));
    if (res.statusCode != 200) {
      // Eklenti yoksa/erişilemezse en son yazılara düş.
      return latest(perPage: limit);
    }
    try {
      final list = json.decode(res.body) as List<dynamic>;
      final parsed = list
          .whereType<Map<String, dynamic>>()
          .where((e) => e['title'] is Map && e['id'] != null)
          .map(V3Post.fromJson)
          .toList();
      return parsed.isEmpty ? await latest(perPage: limit) : parsed;
    } catch (_) {
      return latest(perPage: limit);
    }
  }

  static Future<List<V3Post>> search(String query, {int perPage = 20}) async {
    if (query.trim().isEmpty) return [];
    final res = await http.get(
      _wp('posts', {'search': query.trim(), 'per_page': '$perPage'}),
    );
    return _parseList(res);
  }

  static Future<V3Post?> postById(int id) async {
    final res = await http.get(_wp('posts/$id'));
    if (res.statusCode != 200) return null;
    return V3Post.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  /// Görünür kategoriler — `mobil-app/v1/settings` uç noktasından
  /// (HomePostsWidget ile aynı kaynak).
  static Future<List<V3Category>> categories() async {
    try {
      final res = await http.get(
        Uri.parse('https://dilara.net/wp-json/mobil-app/v1/settings'),
      );
      if (res.statusCode != 200) return const [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = (data['visible_categories'] as List?) ?? const [];
      final parsed = list
          .map((c) => V3Category(
                id: int.tryParse('${c['id']}') ?? 0,
                name: '${c['name'] ?? ''}',
              ))
          .where((c) => c.id != 0 && c.name.isNotEmpty)
          .toList();
      for (final c in parsed) {
        categoryNames[c.id] = c.name;
      }
      return parsed;
    } catch (_) {
      return const [];
    }
  }

  static List<V3Post> _parseList(http.Response res) {
    if (res.statusCode != 200) {
      throw Exception('İçerik yüklenemedi (${res.statusCode})');
    }
    final list = json.decode(res.body) as List<dynamic>;
    return list
        .map((e) => V3Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
