import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'market_models.dart';

/// Uygulama genelinde Market giriş durumunu tutar (state-management paketi
/// olmadığından `ValueNotifier` ile — mevcut kod tabanının stiline uygun).
class MarketAuth {
  MarketAuth._();
  static final MarketAuth instance = MarketAuth._();

  static const _tokenKey = 'market_app_token';

  final ValueNotifier<MarketCustomer?> customer =
      ValueNotifier<MarketCustomer?>(null);

  String? _token;
  bool _restored = false;

  bool get isLoggedIn => _token != null;
  String? get token => _token;

  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setSession(String token, MarketCustomer info) async {
    _token = token;
    customer.value = info;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clear() async {
    _token = null;
    customer.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
