import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../data/market_models.dart';
import '../../theme.dart';

/// "Adreslerim" defterine yeni adres ekler veya var olanı düzenler.
/// `existing` verilirse düzenleme modudur (aynı address_id ile güncellenir).
class AddressFormPage extends StatefulWidget {
  final MarketAddress? existing;

  const AddressFormPage({super.key, this.existing});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _postcode = TextEditingController();

  late Future<Map<String, int>> _citiesFuture;
  String? _city;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _firstname.text = existing.firstname;
      _lastname.text = existing.lastname;
      _address1.text = existing.address1;
      _address2.text = existing.address2;
      _postcode.text = existing.postcode;
    }
    _citiesFuture = MarketApi.instance.turkishCities().then((cities) {
      if (existing != null) {
        // Kayıtlı zone_id'ye karşılık gelen ili bul (isimler sunucudan
        // geldiği için birebir eşleşir).
        for (final entry in cities.entries) {
          if (entry.value == existing.zoneId) {
            _city = entry.key;
            break;
          }
        }
      }
      _city ??= cities.keys.isNotEmpty ? cities.keys.first : null;
      return cities;
    });
  }

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _address1.dispose();
    _address2.dispose();
    _postcode.dispose();
    super.dispose();
  }

  Future<void> _save(Map<String, int> cities) async {
    if (!_formKey.currentState!.validate() || _city == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final address = MarketAddress(
        addressId: widget.existing?.addressId,
        firstname: _firstname.text.trim(),
        lastname: _lastname.text.trim(),
        address1: _address1.text.trim(),
        address2: _address2.text.trim(),
        city: _city!,
        postcode: _postcode.text.trim(),
        zoneId: cities[_city]!,
      );
      final saved = await MarketApi.instance.saveAddress(address);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (_) {
      setState(() => _error = 'Adres kaydedilemedi. Bilgilerinizi kontrol edin.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Yeni Adres' : 'Adresi Düzenle'),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, int>>(
          future: _citiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: V3Colors.primary));
            }
            final cities = snapshot.data;
            if (snapshot.hasError || cities == null || cities.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Şehir listesi yüklenemedi.',
                          style: TextStyle(color: V3Colors.textMuted)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => setState(() {
                          _citiesFuture = MarketApi.instance.turkishCities();
                        }),
                        style:
                            FilledButton.styleFrom(backgroundColor: V3Colors.primary),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _firstname,
                    decoration: const InputDecoration(labelText: 'Ad'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastname,
                    decoration: const InputDecoration(labelText: 'Soyad'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address1,
                    decoration: const InputDecoration(labelText: 'Adres'),
                    minLines: 2,
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().length < 5)
                        ? 'Adresinizi girin'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address2,
                    decoration:
                        const InputDecoration(labelText: 'Adres (devamı, opsiyonel)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _city,
                    decoration: const InputDecoration(labelText: 'İl'),
                    items: cities.keys
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _city = v ?? _city),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postcode,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Posta Kodu'),
                    validator: (v) => (v == null || v.trim().length < 4)
                        ? 'Geçerli bir posta kodu girin'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : () => _save(cities),
                    style: FilledButton.styleFrom(
                      backgroundColor: V3Colors.primary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Kaydet'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
