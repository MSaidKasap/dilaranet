import 'package:flutter/material.dart';

import '../../data/market_api.dart';
import '../../theme.dart';
import 'register_page.dart';

/// Market girişi — başarılı olursa `true` ile pop eder.
class MarketLoginPage extends StatefulWidget {
  const MarketLoginPage({super.key});

  @override
  State<MarketLoginPage> createState() => _MarketLoginPageState();
}

class _MarketLoginPageState extends State<MarketLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
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
      await MarketApi.instance
          .login(email: _email.text.trim(), password: _password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on MarketException catch (e) {
      setState(() {
        _error = e.message == 'invalid_credentials'
            ? 'E-posta veya şifre hatalı.'
            : 'Giriş yapılamadı. Lütfen tekrar deneyin.';
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
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Dilara Yayınları hesabınızla giriş yapın',
                  style: TextStyle(fontSize: 16, color: V3Colors.textMuted)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-posta'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Geçerli bir e-posta girin' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Şifre'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Şifrenizi girin' : null,
                onFieldSubmitted: (_) => _submit(),
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
                    : const Text('Giriş Yap'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                              builder: (_) => const MarketRegisterPage()),
                        );
                        if (!mounted) return;
                        if (ok == true) Navigator.of(context).pop(true);
                      },
                child: const Text('Hesabın yok mu? Üye Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
