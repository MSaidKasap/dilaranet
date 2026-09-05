import 'package:flutter/material.dart';

import '../data/post.dart';
import '../theme.dart';
import 'network_image.dart';

/// news_ui `widgets/single_news_card.dart` uyarlaması — öne çıkan yazı.
class V3HeroCard extends StatelessWidget {
  final V3Post post;
  final String? categoryLabel;
  final VoidCallback onTap;

  const V3HeroCard({
    super.key,
    required this.post,
    required this.onTap,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          V3NetworkImage(
            url: post.imageUrl,
            height: V3Size.h(context, 210),
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(post.relativeTime,
                  style: TextStyle(
                      fontSize: 14, color: V3Colors.textMuted)),
              if ((categoryLabel ?? '').isNotEmpty) ...[
                Text(' | ',
                    style: TextStyle(fontSize: 14, color: V3Colors.textMuted)),
                Text(
                  categoryLabel!,
                  style: const TextStyle(fontSize: 14, color: V3Colors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
