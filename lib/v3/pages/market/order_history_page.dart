import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import 'order_detail_page.dart';

class MarketOrderHistoryPage extends StatefulWidget {
  const MarketOrderHistoryPage({super.key});

  @override
  State<MarketOrderHistoryPage> createState() => _MarketOrderHistoryPageState();
}

class _MarketOrderHistoryPageState extends State<MarketOrderHistoryPage> {
  late Future<List<MarketOrderSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = MarketApi.instance.orders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: FutureBuilder<List<MarketOrderSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: V3Colors.primary));
          }
          final orders = snapshot.data ?? const [];
          if (orders.isEmpty) {
            return Center(
              child: Text('Henüz siparişiniz yok.',
                  style: TextStyle(color: V3Colors.textMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final order = orders[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: V3Colors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text('Sipariş #${order.id}'),
                  subtitle: Text('${order.date} · ${order.status}'),
                  trailing: Text(order.total,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => MarketOrderDetailPage(orderId: order.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
