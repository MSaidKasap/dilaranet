import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import '../../widgets/cart_icon_button.dart';
import '../../widgets/network_image.dart';

class MarketProductDetailPage extends StatefulWidget {
  final int productId;
  final String? title;

  const MarketProductDetailPage({super.key, required this.productId, this.title});

  @override
  State<MarketProductDetailPage> createState() => _MarketProductDetailPageState();
}

class _MarketProductDetailPageState extends State<MarketProductDetailPage> {
  late Future<MarketProductDetail> _future;
  bool _adding = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _future = MarketApi.instance.product(widget.productId);
  }

  Future<void> _addToCart() async {
    setState(() {
      _adding = true;
      _message = null;
    });
    try {
      await MarketApi.instance.addToCart(widget.productId);
      setState(() => _message = 'Sepete eklendi.');
    } catch (_) {
      setState(() => _message = 'Sepete eklenemedi, tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Ürün'),
        actions: const [V3CartIconButton()],
      ),
      body: FutureBuilder<MarketProductDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: V3Colors.primary));
          }
          if (!snapshot.hasData) {
            return Center(
                child: Text('Ürün yüklenemedi.',
                    style: TextStyle(color: V3Colors.textMuted)));
          }
          final product = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (product.images.isNotEmpty)
                SizedBox(
                  height: 260,
                  child: PageView(
                    children: product.images
                        .map((url) => V3NetworkImage(
                              url: url,
                              width: double.infinity,
                              height: 260,
                              borderRadius: BorderRadius.circular(16),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(product.name,
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (product.special != null) ...[
                    Text(product.price,
                        style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: V3Colors.textMuted)),
                    const SizedBox(width: 8),
                    Text(product.special!,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: V3Colors.primary)),
                  ] else
                    Text(product.price,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: V3Colors.primary)),
                  const SizedBox(width: 12),
                  Text(
                    product.inStock ? 'Stokta var' : 'Stokta yok',
                    style: TextStyle(
                        color: product.inStock ? Colors.green : Colors.red,
                        fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (product.descriptionHtml.trim().isNotEmpty)
                HtmlWidget(
                  product.descriptionHtml,
                  textStyle: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color.fromRGBO(60, 64, 78, 1)),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_message!,
                      style: TextStyle(color: V3Colors.textMuted)),
                ),
              FilledButton.icon(
                onPressed: _adding ? null : _addToCart,
                style: FilledButton.styleFrom(
                  backgroundColor: V3Colors.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: _adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_shopping_cart),
                label: const Text('Sepete Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
