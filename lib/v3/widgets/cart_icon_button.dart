import 'package:flutter/material.dart';

import '../data/market_api.dart';
import '../pages/market/cart_page.dart';
import '../theme.dart';

/// Sepete giden ve içindeki ürün adedini bildirim gibi kırmızı bir
/// rozette gösteren simge. `MarketApi.instance.cartCount`'u dinler.
class V3CartIconButton extends StatelessWidget {
  final Color color;
  final double size;

  const V3CartIconButton({
    super.key,
    this.color = V3Colors.textPrimary,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MarketApi.instance.cartCount,
      builder: (context, count, _) {
        return IconButton(
          icon: Badge(
            isLabelVisible: count > 0,
            backgroundColor: Colors.red,
            label: Text(count > 99 ? '99+' : '$count'),
            child: Icon(Icons.shopping_cart_outlined, size: size, color: color),
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MarketCartPage()),
          ),
        );
      },
    );
  }
}
