import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import '../../widgets/cart_icon_button.dart';
import 'category_products_page.dart';
import 'market_search_page.dart';
import 'product_card.dart';
import 'product_detail_page.dart';

/// Market sekmesinin ana içeriği (Ana Sayfa/Bölümler gibi shell'in
/// IndexedStack'i içine gömülür — kendi Scaffold/AppBar'ı yok).
class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  late Future<List<MarketCategory>> _categoriesFuture;
  late Future<({List<MarketProduct> products, int total, int page})> _featuredFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = MarketApi.instance.categories();
    _featuredFuture = MarketApi.instance.products(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: V3Colors.primary,
      onRefresh: () async {
        setState(() {
          _categoriesFuture = MarketApi.instance.categories();
          _featuredFuture = MarketApi.instance.products(page: 1);
        });
        await Future.wait([_categoriesFuture, _featuredFuture]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Market',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MarketSearchPage()),
                    ),
                  ),
                  const V3CartIconButton(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Dilara Yayınları kitapları',
              style: TextStyle(color: V3Colors.textMuted)),
          const SizedBox(height: 16),
          FutureBuilder<List<MarketCategory>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              final categories = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 40,
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: V3Colors.primary)),
                );
              }
              if (categories.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _CategoryChip(
                      label: category.name,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoryProductsPage(
                            categoryId: category.id,
                            title: category.name,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Öne Çıkan Kitaplar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          FutureBuilder(
            future: _featuredFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                      child: CircularProgressIndicator(color: V3Colors.primary)),
                );
              }
              final products = snapshot.data?.products ?? const [];
              if (products.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('Ürünler yüklenemedi.',
                        style: TextStyle(color: V3Colors.textMuted)),
                  ),
                );
              }
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
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
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: V3Colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
