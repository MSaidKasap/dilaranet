import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';

class MarketOrderDetailPage extends StatefulWidget {
  final int orderId;

  const MarketOrderDetailPage({super.key, required this.orderId});

  @override
  State<MarketOrderDetailPage> createState() => _MarketOrderDetailPageState();
}

class _MarketOrderDetailPageState extends State<MarketOrderDetailPage> {
  late Future<MarketOrderDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = MarketApi.instance.orderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sipariş #${widget.orderId}')),
      body: FutureBuilder<MarketOrderDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: V3Colors.primary));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Sipariş bulunamadı. Ödemeniz henüz onaylanmamış olabilir; '
                  'birkaç dakika içinde "Siparişlerim" bölümünden tekrar kontrol edin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: V3Colors.textMuted),
                ),
              ),
            );
          }
          final order = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: V3Colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.date,
                            style: const TextStyle(color: V3Colors.textMuted)),
                        const SizedBox(height: 4),
                        Text(order.shippingAddress,
                            style: const TextStyle(color: V3Colors.textMuted)),
                      ],
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: V3Colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(order.status,
                          style: const TextStyle(
                              color: V3Colors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Ürünler',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              for (final p in order.products)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text('${p.name}  x${p.quantity}'),
                      ),
                      Text(p.total, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              const Divider(height: 32),
              for (final t in order.totals)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.title, style: const TextStyle(color: V3Colors.textMuted)),
                      Text(t.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              if (order.histories.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Sipariş Geçmişi',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                for (final h in order.histories)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(h.status),
                        Text(h.date, style: const TextStyle(color: V3Colors.textMuted)),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
