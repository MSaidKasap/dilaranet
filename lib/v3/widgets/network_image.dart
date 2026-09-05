import 'package:flutter/material.dart';

import '../theme.dart';

/// Ortak görsel bileşeni: yükleme/ha­ta durumlarını tek yerde yönetir.
class V3NetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const V3NetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: width,
      height: height,
      color: V3Colors.surface,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined,
          color: V3Colors.textMuted, size: 32),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: url.startsWith('http')
          ? Image.network(
              url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: width,
                  height: height,
                  color: V3Colors.surface,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: V3Colors.primary),
                  ),
                );
              },
            )
          : fallback,
    );
  }
}
