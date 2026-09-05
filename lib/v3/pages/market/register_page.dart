import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../theme.dart';

/// Yeni üyelik — başarılı olursa `true` ile pop eder (otomatik giriş yapılmış olur).
class MarketRegisterPage extends StatefulWidget {
  const MarketRegisterPage({super.key});

  @override
  State<MarketRegisterPage> createState() => _MarketRegisterPageState();
}

class _MarketRegisterPageState extends State<MarketRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _email.dispose();
    _telephone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await MarketApi.instance.register(
        firstname: _firstname.text.trim(),
        lastname: _lastname.text.trim(),
        email: _email.text.trim(),
        telephone: _telephone.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on MarketException catch (e) {
      setState(() {
        _error = e.message == 'email_exists'
            ? 'Bu e-posta adresi zaten kayıtlı.'
            : 'Üyelik oluşturulamadı. Bilgilerinizi kontrol edin.';
      });
    } catch (_) {
      setState(() => _error = 'Bağlantı hatası. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üye Ol')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _firstname,
                decoration: const InputDecoration(labelText: 'Ad'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastname,
                decoration: const InputDecoration(labelText: 'Soyad'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Geçerli bir e-posta girin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telephone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefon'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre'),
                validator: (v) => (v == null || v.length < 4)
                    ? 'En az 4 karakter olmalı'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: V3Colors.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Üye Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
