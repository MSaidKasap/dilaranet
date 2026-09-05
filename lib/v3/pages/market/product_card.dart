import 'package:flutter/material.dart';

import '../../data/market_models.dart';
import '../../theme.dart';
import '../../widgets/network_image.dart';

class MarketProductCard extends StatelessWidget {
  final MarketProduct product;
  final VoidCallback onTap;

  const MarketProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: V3Colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: V3NetworkImage(
                url: product.image,
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  if (product.special != null) ...[
                    Text(product.price,
                        style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: V3Colors.textMuted)),
                    Text(product.special!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: V3Colors.primary)),
                  ] else
                    Text(product.price,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: V3Colors.primary)),
                  if (!product.inStock)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Stokta yok',
                          style: TextStyle(fontSize: 11, color: Colors.red)),
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
