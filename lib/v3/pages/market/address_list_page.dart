import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';
import 'address_form_page.dart';

/// Hesabın "Adreslerim" bölümü: sitede kayıtlı tüm teslimat & fatura
/// adreslerini listeler, ekleme/düzenleme/silmeye izin verir.
class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  late Future<List<MarketAddress>> _future;

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

  Future<void> _add() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressFormPage()),
    );
    _reload();
  }

  Future<void> _edit(MarketAddress address) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddressFormPage(existing: address)),
    );
    _reload();
  }

  Future<void> _delete(MarketAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adresi Sil'),
        content: const Text('Bu adresi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || address.addressId == null) return;
    await MarketApi.instance.deleteAddress(address.addressId!);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adreslerim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: V3Colors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Adres'),
      ),
      body: FutureBuilder<List<MarketAddress>>(
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
                      style:
                          FilledButton.styleFrom(backgroundColor: V3Colors.primary),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }
          final addresses = snapshot.data ?? const [];
          if (addresses.isEmpty) {
            return Center(
              child: Text('Henüz bir adres eklemediniz.',
                  style: TextStyle(color: V3Colors.textMuted)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: V3Colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('${address.firstname} ${address.lastname}',
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        if (address.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: V3Colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Varsayılan',
                                style: TextStyle(
                                    color: V3Colors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(address.address1),
                    if (address.address2.isNotEmpty) Text(address.address2),
                    Text('${address.city} ${address.postcode}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _edit(address),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Düzenle'),
                        ),
                        TextButton.icon(
                          onPressed: () => _delete(address),
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          label:
                              const Text('Sil', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
