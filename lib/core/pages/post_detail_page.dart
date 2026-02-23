import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../utill/app_constants.dart';

class PostDetail extends StatefulWidget {
  final int postId;

  const PostDetail({super.key, required this.postId});

  @override
  // ignore: library_private_types_in_public_api
  _PostDetailState createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  dynamic _post;

  @override
  void initState() {
    super.initState();
    fetchPost();
  }

  Future<void> fetchPost() async {
    try {
      final post = await WPAPIPOST.fetchPosts(widget.postId);
      setState(() {
        _post = post;
      });
    } catch (e) {
      // print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_post != null ? _post['title']['rendered'] : ''),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _post != null
              ? HtmlWidget(_post['content']['rendered'])
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
