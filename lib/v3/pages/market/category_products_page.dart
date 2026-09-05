import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import 'product_card.dart';
import 'product_detail_page.dart';

class CategoryProductsPage extends StatefulWidget {
  final int? categoryId;
  final String? search;
  final String title;

  const CategoryProductsPage(
      {super.key, this.categoryId, this.search, required this.title});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final _products = <MarketProduct>[];
  int _page = 1;
  int _total = 0;
  bool _loading = false;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    setState(() => _loading = true);
    try {
      final result = await MarketApi.instance.products(
        categoryId: widget.categoryId,
        search: widget.search,
        page: page,
      );
      setState(() {
        if (page == 1) _products.clear();
        _products.addAll(result.products);
        _total = result.total;
        _page = page;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialLoadDone = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: !_initialLoadDone
          ? const Center(child: CircularProgressIndicator(color: V3Colors.primary))
          : _products.isEmpty
              ? Center(
                  child: Text('Ürün bulunamadı.',
                      style: TextStyle(color: V3Colors.textMuted)))
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (!_loading &&
                        _products.length < _total &&
                        notification.metrics.pixels >
                            notification.metrics.maxScrollExtent - 200) {
                      _loadPage(_page + 1);
                    }
                    return false;
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (context, index) {
                      final product = _products[index];
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
                  ),
                ),
    );
  }
}
