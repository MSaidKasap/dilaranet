import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import 'address_list_page.dart';
import 'checkout_review_page.dart';

/// Sepetteki "Siparişi Tamamla" akışının ilk adımı. Hesabın "Adreslerim"
/// defterindeki varsayılan (yoksa ilk) adresi gösterir; değiştirmek isteyen
/// kullanıcı "Düzenle" ile profildeki adres defterine gider.
class CheckoutAddressPage extends StatefulWidget {
  const CheckoutAddressPage({super.key});

  @override
  State<CheckoutAddressPage> createState() => _CheckoutAddressPageState();
}

class _CheckoutAddressPageState extends State<CheckoutAddressPage> {
  late Future<List<MarketAddress>> _future;
  bool _placing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = MarketApi.instance.addresses();
    });
  }

  MarketAddress? _pick(List<MarketAddress> addresses) {
    if (addresses.isEmpty) return null;
    return addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
  }

  Future<void> _editAddress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressListPage()),
    );
    _reload();
  }

  Future<void> _continue(MarketAddress address) async {
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      await MarketApi.instance.saveShippingAddress(address);
      await MarketApi.instance.savePaymentAddress(address);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CheckoutReviewPage()),
      );
    } catch (_) {
      setState(() => _error = 'Adres kaydedilemedi. Bilgilerinizi kontrol edin.');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teslimat & Fatura Adresi')),
      body: SafeArea(
        child: FutureBuilder<List<MarketAddress>>(
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
                      Text('Adresler yüklenemedi.',
                          style: TextStyle(color: V3Colors.textMuted)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _reload,
                        style: FilledButton.styleFrom(
                            backgroundColor: V3Colors.primary),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              );
            }
            final address = _pick(snapshot.data ?? const []);
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (address == null) ...[
                  Text(
                    'Henüz bir teslimat & fatura adresi eklemediniz.',
                    style: TextStyle(color: V3Colors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _editAddress,
                    style: FilledButton.styleFrom(
                      backgroundColor: V3Colors.primary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Adres Ekle'),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: V3Colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${address.firstname} ${address.lastname}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(address.address1),
                        if (address.address2.isNotEmpty) Text(address.address2),
                        Text('${address.city} ${address.postcode}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _editAddress,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: V3Colors.primary,
                      side: const BorderSide(color: V3Colors.primary),
                    ),
                    child: const Text('Düzenle'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _placing ? null : () => _continue(address),
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
                        : const Text('Devam Et'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
