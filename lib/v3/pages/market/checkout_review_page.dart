import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import 'order_detail_page.dart';
import 'payment_webview_page.dart';

class CheckoutReviewPage extends StatefulWidget {
  const CheckoutReviewPage({super.key});

  @override
  State<CheckoutReviewPage> createState() => _CheckoutReviewPageState();
}

class _CheckoutReviewPageState extends State<CheckoutReviewPage> {
  late Future<List<MarketShippingQuote>> _quotesFuture;
  String? _selectedCode;
  bool _placing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quotesFuture = MarketApi.instance.shippingQuotes().then((quotes) {
      if (quotes.isNotEmpty) _selectedCode = quotes.first.code;
      return quotes;
    });
  }

  Future<void> _placeOrder() async {
    if (_selectedCode == null) return;
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      await MarketApi.instance.saveShippingMethod(_selectedCode!);
      await MarketApi.instance.paymentQuotesTotal();
      await MarketApi.instance.savePaymentMethod();
      await MarketApi.instance.confirmOrder();
      final result = await MarketApi.instance.paytrToken();

      if (!mounted) return;
      final paymentResult = await Navigator.of(context).push<MarketPaymentResult>(
        MaterialPageRoute(
          builder: (_) =>
              MarketPaymentWebviewPage(paymentUrl: result.paymentUrl),
        ),
      );

      if (!mounted) return;

      if (paymentResult == MarketPaymentResult.success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MarketOrderDetailPage(orderId: result.orderId),
          ),
          (route) => route.isFirst,
        );
      } else {
        setState(() => _error =
            'Ödeme tamamlanmadı. Siparişiniz sepetinizde bekliyor, tekrar deneyebilirsiniz.');
      }
    } on MarketException catch (e) {
      setState(() => _error = 'Sipariş oluşturulamadı (${e.message}).');
    } catch (_) {
      setState(() => _error = 'Bir şeyler ters gitti, lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sipariş Özeti')),
      body: FutureBuilder<List<MarketShippingQuote>>(
        future: _quotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: V3Colors.primary));
          }
          final quotes = snapshot.data ?? const [];
          if (quotes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                    'Bu adrese uygun bir kargo seçeneği bulunamadı. Lütfen adresinizi kontrol edin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: V3Colors.textMuted)),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('Kargo Seçeneği',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              for (final quote in quotes)
                RadioListTile<String>(
                  value: quote.code,
                  groupValue: _selectedCode,
                  onChanged: (v) => setState(() => _selectedCode = v),
                  activeColor: V3Colors.primary,
                  title: Text(quote.title),
                  subtitle: Text(quote.text),
                ),
              const SizedBox(height: 20),
              const Text('Ödeme Yöntemi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              const ListTile(
                leading: Icon(Icons.credit_card, color: V3Colors.primary),
                title: Text('Kredi / Banka Kartı (PayTR)'),
                subtitle: Text('Kart bilgileriniz güvenli PayTR sayfasında alınır.'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _placing ? null : _placeOrder,
                style: FilledButton.styleFrom(
                  backgroundColor: V3Colors.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _placing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Ödemeye Geç'),
              ),
            ],
          );
        },
      ),
    );
  }
}
