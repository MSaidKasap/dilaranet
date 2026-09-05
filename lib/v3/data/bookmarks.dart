import 'package:shared_preferences/shared_preferences.dart';

/// Basit yer imi deposu. Eski `post_page.dart` ile uyumlu kalması için
/// her yazının id'si ayrıca bool anahtar olarak da tutulur.
class V3Bookmarks {
  static const _listKey = 'v3_bookmark_ids';

  static Future<List<int>> ids() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_listKey) ?? const [])
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e != 0)
        .toList();
  }

  static Future<bool> contains(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(id.toString()) ??
        (prefs.getStringList(_listKey) ?? const []).contains(id.toString());
  }

  static Future<bool> toggle(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_listKey) ?? <String>[];
    final key = id.toString();
    final nowSaved = !list.contains(key);
    if (nowSaved) {
      list.add(key);
    } else {
      list.remove(key);
    }
    await prefs.setStringList(_listKey, list);
    await prefs.setBool(key, nowSaved);
    return nowSaved;
  }
}
