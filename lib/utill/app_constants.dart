import 'package:http/http.dart' as http;
import 'dart:convert';

const String APP_TITLE = "images/logo.png";
const String URL = "https://www.dilara.net/";
const int FEATURED_CATEGORY_ID = 0;
const String FEATURED_CATEGORY_TITLE = 'Featured';
const isRTL = false;
const String URLPLS = 'wp-json/wp/v2';

Future<List<dynamic>> fetchLatestPosts() async {
  final response = await http.get(Uri.parse('$URL$URLPLS/posts?per_page=10'));

  if (response.statusCode == 200) {
    final List<dynamic> parsedJson = json.decode(response.body);
    return parsedJson;
  } else {
    throw Exception('Yayınlar yüklenemedi');
  }
}

Future<List<dynamic>> fetchPostsByCategory(int categoryId) async {
  final response =
      await http.get(Uri.parse('$URL$URLPLS/posts?categories=$categoryId'));
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data;
  } else {
    throw Exception('Yayınlar yüklenemedi');
  }
}

Future<String> fetchPostContent(int postId) async {
  final response = await http.get(Uri.parse('$URL$URLPLS/posts/$postId'));
  if (response.statusCode == 200) {
    final Map<String, dynamic> parsedJson = json.decode(response.body);
    final content = parsedJson['content']['rendered'];
    return content;
  } else {
    throw Exception('Yayınlar yüklenemedi');
  }
}

class WPAPIPOST {
  static Future<dynamic> fetchPosts(int postId) async {
    final response = await http.get(Uri.parse('$URL$URLPLS/posts/$postId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Yayınlar yüklenemedi');
    }
  }
}

Future<List<dynamic>> fetchPostPop() async {
  final response = await http.get(Uri.parse(
      '$URL/wp-json/wordpress-popular-posts/v1/popular-posts?range=all&limit=10'));

  if (response.statusCode == 200) {
    final List<dynamic> parsedJson = json.decode(response.body);

    return parsedJson;
  } else {
    throw Exception('Yayınlar yüklenemedi');
  }
}
