// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:html_character_entities/html_character_entities.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utill/app_constants.dart';
import 'post_page.dart';

class HomePostLower extends StatefulWidget {
  const HomePostLower({Key? key}) : super(key: key);

  get categoryId => null;

  @override
  State<HomePostLower> createState() => _HomePostLowerState();
}

class _HomePostLowerState extends State<HomePostLower> {
  // ignore: unused_field
  List<dynamic> _posts = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final response = await http.get(
      Uri.parse(
        '$URL$URLPLS/posts?categories=${widget.categoryId.toString()}&per_page=100&page=1&orderby=date&order=desc',
      ),
    );
    if (response.statusCode == 200) {
      setState(() {
        _posts = json.decode(response.body);
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  // ignore: unused_element
  void _checkIfFavorite(dynamic post) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String postId = post['id'].toString();
    setState(() {
      _isFavorite = prefs.getBool(postId) ?? false;
    });
  }

  Future<void> _toggleFavorite(dynamic post) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String postId = post['id'].toString();

    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      prefs.setBool(postId, true);
    } else {
      prefs.remove(postId);
    }
  }

  Future<void> _sharePost(dynamic post) async {
    try {
      String cleanedContent = HtmlCharacterEntities.decode(
        post['content']['rendered'].replaceAll(RegExp(r'<[^>]*>'), ''),
      );

      await Share.share(post['title']['rendered'] + '\n\n' + cleanedContent);
    } catch (e) {
      // ignore: avoid_print
      print('Sharing error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FutureBuilder<List<dynamic>>(
        future: fetchPostPop(), // Kategori 9'a göre gönderileri çek
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts available.'));
          } else {
            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                final imageUrl = post['jetpack_featured_media_url'];
                final title = post['title']['rendered'];

                final versionHistory = post['_links']['version-history'];
                // ignore: unused_local_variable
                final count = versionHistory.isNotEmpty
                    ? versionHistory[0]['count']
                    : 0;

                //  print(versionHistory);

                return FutureBuilder<String>(
                  future: fetchPostContent(post['id']),
                  builder: (context, snapshotContent) {
                    if (snapshotContent.connectionState ==
                        ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshotContent.hasError) {
                      return Text('Error: ${snapshotContent.error}');
                    } else {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailPage(post),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          padding: const EdgeInsets.all(8.0), // Padding eklendi
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: const Color.fromARGB(255, 12, 90, 200),
                              width: 2.0,
                            ),
                            shape: BoxShape.rectangle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  3,
                                  3,
                                  3,
                                ).withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                imageUrl,
                                width: double
                                    .infinity, // Resmin genişliği ayarlandı
                                height: 150, // Resmin yüksekliği ayarlandı
                                fit: BoxFit.cover, // Resmin boyutu ayarlandı
                              ),
                              const SizedBox(height: 8), // Boşluk eklendi
                              HtmlWidget(title),

                              const SizedBox(height: 8), // Boşluk eklendi
                              Column(
                                children: [
                                  const Divider(
                                    color: Colors.grey, // Çizgi rengi
                                    height: 0, // Çizgi yüksekliği
                                    thickness: 1, // Çizgi kalınlığı
                                    indent: 0, // Sol boşluk
                                    endIndent: 0, // Sağ boşluk
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment
                                        .spaceBetween, // İkonların arasındaki boşluğu maksimuma ayarlar
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.favorite),
                                        onPressed: () {
                                          _toggleFavorite(
                                            post,
                                          ); // Beğeni işlevi eklenecek
                                        },
                                        color: _isFavorite ? Colors.red : null,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.share),
                                        onPressed: () {
                                          _sharePost(
                                            post,
                                          ); // Paylaşma işlevi eklenecek
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
