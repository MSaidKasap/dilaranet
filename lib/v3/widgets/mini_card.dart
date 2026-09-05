import 'package:flutter/material.dart';

import '../data/post.dart';
import '../theme.dart';
import 'network_image.dart';

/// news_ui `widgets/mini_news_card.dart` uyarlaması — liste satırı.
class V3MiniCard extends StatelessWidget {
  final V3Post post;
  final String? categoryLabel;
  final VoidCallback onTap;

  const V3MiniCard({
    super.key,
    required this.post,
    required this.onTap,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: V3Colors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            V3NetworkImage(
              url: post.imageUrl,
              width: V3Size.w(context, 110),
              height: V3Size.w(context, 110),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: V3Colors.textMuted, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.relativeTime,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13, color: V3Colors.textMuted),
                        ),
                      ),
                      if ((categoryLabel ?? '').isNotEmpty) ...[
                        Text(' | ',
                            style: TextStyle(
                                fontSize: 13, color: V3Colors.textMuted)),
                        Flexible(
                          child: Text(
                            categoryLabel!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: V3Colors.primary),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
