import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_auth.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import '../../widgets/network_image.dart';
import 'checkout_address_page.dart';
import 'login_page.dart';

class MarketCartPage extends StatefulWidget {
  const MarketCartPage({super.key});

  @override
  State<MarketCartPage> createState() => _MarketCartPageState();
}

class _MarketCartPageState extends State<MarketCartPage> {
  late Future<MarketCart> _future;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = MarketApi.instance.cart();
    });
  }

  Future<void> _updateQty(MarketCartItem item, int quantity) async {
    setState(() => _busy = true);
    try {
      if (quantity <= 0) {
        await MarketApi.instance.removeCartItem(item.cartId);
      } else {
        await MarketApi.instance.updateCartItem(item.cartId, quantity);
      }
      _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkout() async {
    if (!MarketAuth.instance.isLoggedIn) {
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const MarketLoginPage()));
      if (!mounted || ok != true) return;
    }
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CheckoutAddressPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sepetim')),
      body: FutureBuilder<MarketCart>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: V3Colors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sepet yüklenemedi.',
                        style: TextStyle(color: V3Colors.textMuted)),
                    const SizedBox(height: 4),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: V3Colors.textMuted, fontSize: 12)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      style:
                          FilledButton.styleFrom(backgroundColor: V3Colors.primary),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }
          final cart = snapshot.data;
          if (cart == null || cart.isEmpty) {
            return const Center(
              child: Text('Sepetiniz boş.',
                  style: TextStyle(color: V3Colors.textMuted)),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            children: [
              for (final item in cart.items) ...[
                _CartRow(
                  item: item,
                  busy: _busy,
                  onQuantityChanged: (q) => _updateQty(item, q),
                ),
                const SizedBox(height: 12),
              ],
              const Divider(height: 32),
              for (final total in cart.totals)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(total.title,
                          style: const TextStyle(color: V3Colors.textMuted)),
                      Text(total.text,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _checkout,
                style: FilledButton.styleFrom(
                  backgroundColor: V3Colors.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Siparişi Tamamla'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final MarketCartItem item;
  final bool busy;
  final ValueChanged<int> onQuantityChanged;

  const _CartRow(
      {required this.item, required this.busy, required this.onQuantityChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        V3NetworkImage(url: item.image, width: 72, height: 72),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(item.total,
                  style: const TextStyle(color: V3Colors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: busy ? null : () => onQuantityChanged(item.quantity - 1),
                  ),
                  Text('${item.quantity}'),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: busy ? null : () => onQuantityChanged(item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
