import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import 'product_card.dart';
import 'product_detail_page.dart';

class MarketSearchPage extends StatefulWidget {
  const MarketSearchPage({super.key});

  @override
  State<MarketSearchPage> createState() => _MarketSearchPageState();
}

class _MarketSearchPageState extends State<MarketSearchPage> {
  final _controller = TextEditingController();
  Future<({List<MarketProduct> products, int total, int page})>? _future;
  String _lastQuery = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run() {
    final q = _controller.text.trim();
    if (q.isEmpty || q == _lastQuery) return;
    setState(() {
      _lastQuery = q;
      _future = MarketApi.instance.products(search: q);
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitap Ara')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: V3Colors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: V3Colors.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _run(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Kitap adı ara...',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _run,
                    icon: const Icon(Icons.arrow_forward, color: V3Colors.primary),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _future == null
                ? const Center(
                    child: Text('Bir kitap adı yazıp arayın.',
                        style: TextStyle(color: V3Colors.textMuted)),
                  )
                : FutureBuilder(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: V3Colors.primary),
                        );
                      }
                      final products = snapshot.data?.products ?? const [];
                      if (products.isEmpty) {
                        return Center(
                          child: Text('"$_lastQuery" için sonuç bulunamadı.',
                              style: const TextStyle(color: V3Colors.textMuted)),
                        );
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.62,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return MarketProductCard(
                            product: product,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MarketProductDetailPage(
                                    productId: product.id, title: product.name),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
