import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'market_auth.dart';
import 'market_models.dart';

class MarketException implements Exception {
  final String message;
  const MarketException(this.message);
  @override
  String toString() => message;
}

/// dilarayayinlari.com (OpenCart 3.0.3.2) ile konuşan istemci.
///
/// Bir `CookieJar` kullanarak OpenCart'ın oturum çerezini (OCSESSID) tüm
/// istekler arasında bir tarayıcı gibi taşır — sepet/checkout akışı bu
/// çereze bağlı olarak sunucu tarafında saklanır. Kimlik doğrulaması için
/// ayrıca `X-App-Token` header'ı gönderilir (bkz. sunucudaki
/// `extension/module/mobileapi.php`).
class MarketApi {
  MarketApi._();
  static final MarketApi instance = MarketApi._();

  static const String baseUrl = 'https://dilarayayinlari.com/index.php';

  /// Sepetteki ürün adedi — app bar/rozet gibi yerlerin dinlediği global
  /// sayaç. `cart()` ve sepeti değiştiren uçlar bunu günceller.
  final ValueNotifier<int> cartCount = ValueNotifier<int>(0);

  Future<Dio>? _dioFuture;

  Future<Dio> _client() => _dioFuture ??= _createClient();

  Future<Dio> _createClient() async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      validateStatus: (_) => true,
    ));
    // OCSESSID çerezini diske yazar; aksi halde hot restart/uygulamayı
    // kapatıp açmak sepeti sıfırlıyordu (sunucu her seferinde yeni bir
    // misafir oturumu görüyordu).
    final dir = await getApplicationSupportDirectory();
    final cookieJar = PersistCookieJar(storage: FileStorage('${dir.path}/.cookies/'));
    dio.interceptors.add(CookieManager(cookieJar));
    return dio;
  }

  Map<String, String> _authHeaders() {
    final token = MarketAuth.instance.token;
    return token == null ? {} : {'X-App-Token': token};
  }

  Future<Map<String, dynamic>> _get(String route,
      {Map<String, dynamic>? query}) async {
    final dio = await _client();
    final res = await dio.get(
      baseUrl,
      queryParameters: {'route': route, ...?query},
      options: Options(headers: _authHeaders()),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> _post(String route,
      {Map<String, dynamic>? data, bool asJson = false}) async {
    final dio = await _client();
    final res = await dio.post(
      baseUrl,
      queryParameters: {'route': route},
      data: data ?? {},
      options: Options(
        headers: _authHeaders(),
        contentType: asJson ? Headers.jsonContentType : null,
      ),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(Response res) {
    final body = res.data;
    final Map<String, dynamic> json = body is Map<String, dynamic>
        ? body
        : (body is List ? {} : <String, dynamic>{});

    if (res.statusCode == 401) {
      throw const MarketException('unauthorized');
    }
    if (json['error'] != null) {
      throw MarketException(json['error'].toString());
    }
    if (res.statusCode != null && res.statusCode! >= 400) {
      throw MarketException('http_${res.statusCode}');
    }
    return json;
  }

  // ---------------------------------------------------------------
  // Katalog
  // ---------------------------------------------------------------

  Future<List<MarketCategory>> categories() async {
    final json = await _get('extension/module/mobileapi/categories');
    return (json['categories'] as List<dynamic>? ?? [])
        .map((c) => MarketCategory.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<({List<MarketProduct> products, int total, int page})> products({
    int? categoryId,
    String? search,
    int page = 1,
  }) async {
    final json = await _get('extension/module/mobileapi/products', query: {
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
    });
    final list = (json['products'] as List<dynamic>? ?? [])
        .map((p) => MarketProduct.fromJson(p as Map<String, dynamic>))
        .toList();
    return (products: list, total: json['total'] as int? ?? 0, page: page);
  }

  Future<MarketProductDetail> product(int productId) async {
    final json = await _get('extension/module/mobileapi/product',
        query: {'product_id': productId});
    return MarketProductDetail.fromJson(
        json['product'] as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------
  // Hesap
  // ---------------------------------------------------------------

  Future<void> register({
    required String firstname,
    required String lastname,
    required String email,
    required String telephone,
    required String password,
  }) async {
    final json = await _post('extension/module/mobileapi/register', asJson: true, data: {
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'telephone': telephone,
      'password': password,
    });
    await MarketAuth.instance.setSession(
      json['token'] as String,
      MarketCustomer.fromJson(json['customer'] as Map<String, dynamic>),
    );
  }

  Future<void> login({required String email, required String password}) async {
    final json = await _post('extension/module/mobileapi/login', asJson: true, data: {
      'email': email,
      'password': password,
    });
    await MarketAuth.instance.setSession(
      json['token'] as String,
      MarketCustomer.fromJson(json['customer'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    try {
      // Bu uç POST'u 403 ile reddediyor (WAF/route sadece GET kabul ediyor);
      // sunucu tarafı oturum bu yüzden hiç kapanmıyordu.
      await _get('extension/module/mobileapi/logout');
    } catch (_) {
      // Yerel oturumu yine de temizle.
    }
    await MarketAuth.instance.clear();
  }

  // ---------------------------------------------------------------
  // Sepet
  // ---------------------------------------------------------------

  Future<MarketCart> cart() async {
    final json = await _get('extension/module/mobileapi/cart');
    final cart = MarketCart.fromJson(json);
    cartCount.value = cart.itemCount;
    return cart;
  }

  Future<void> addToCart(int productId, {int quantity = 1}) async {
    final json = await _post('checkout/cart/add', data: {
      'product_id': productId,
      'quantity': quantity,
    });
    final count = json['items_count'];
    if (count is int) cartCount.value = count;
  }

  Future<void> updateCartItem(String cartId, int quantity) async {
    // checkout/cart/edit `quantity[cart_id]=n` biçiminde bir dizi bekler
    // (stok OpenCart temasının toplu sepet formuyla aynı alan adı).
    // Bu uç JSON değil bir yönlendirme döndürüyor; sayaç çağıran taraftaki
    // cart() yenilemesiyle güncellenir.
    await _post('checkout/cart/edit', data: {
      'quantity[$cartId]': quantity,
    });
  }

  Future<void> removeCartItem(String cartId) async {
    final json = await _post('checkout/cart/remove', data: {'key': cartId});
    final count = json['items_count'];
    if (count is int) cartCount.value = count;
  }

  // ---------------------------------------------------------------
  // Adres defteri ("Adreslerim")
  // ---------------------------------------------------------------

  Future<List<MarketAddress>> addresses() async {
    final json = await _get('extension/module/mobileapi/addresses');
    return (json['addresses'] as List<dynamic>? ?? [])
        .map((e) => MarketAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MarketAddress> saveAddress(MarketAddress address,
      {bool makeDefault = false}) async {
    final json = await _post('extension/module/mobileapi/addressSave',
        asJson: true,
        data: {
          ...address.toRequestData(),
          if (makeDefault) 'default': true,
        });
    return MarketAddress.fromJson(json['address'] as Map<String, dynamic>);
  }

  Future<void> deleteAddress(int addressId) async {
    await _post('extension/module/mobileapi/addressDelete',
        asJson: true, data: {'address_id': addressId});
  }

  /// Sitenin checkout eklentisinin canlı il/ilçe (zone) listesi — statik bir
  /// kopya tutmak yerine doğrudan sunucudan çekilir.
  Future<Map<String, int>> turkishCities() async {
    final json = await _get('extension/quickcheckout/checkout/country',
        query: {'country_id': 215});
    final map = <String, int>{};
    for (final entry in (json['zone'] as List<dynamic>? ?? [])) {
      final zone = entry as Map<String, dynamic>;
      final name = zone['name'] as String?;
      final id = int.tryParse('${zone['zone_id']}');
      if (name != null && id != null) map[name] = id;
    }
    return map;
  }

  // ---------------------------------------------------------------
  // Checkout
  // ---------------------------------------------------------------

  Future<void> saveShippingAddress(MarketAddress address) async {
    await _post('checkout/shipping_address/save', data: {
      ...address.toFormData(),
      'shipping_address': 'new',
    });
  }

  Future<void> savePaymentAddress(MarketAddress address) async {
    await _post('checkout/payment_address/save', data: {
      ...address.toFormData(),
      'payment_address': 'new',
    });
  }

  Future<List<MarketShippingQuote>> shippingQuotes() async {
    final json = await _get('extension/module/mobileapi/shippingQuotes');
    return parseShippingQuotes(json);
  }

  Future<void> saveShippingMethod(String code) async {
    await _post('checkout/shipping_method/save', data: {
      'shipping_method': code,
      'comment': '',
    });
  }

  Future<int> paymentQuotesTotal() async {
    final json = await _get('extension/module/mobileapi/paymentQuotes');
    return (json['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> savePaymentMethod() async {
    await _post('checkout/payment_method/save', data: {
      'payment_method': 'paytr_checkout',
      'agree': '1',
    });
  }

  Future<void> confirmOrder() async {
    final dio = await _client();
    await dio.get(baseUrl,
        queryParameters: {'route': 'checkout/confirm'},
        options: Options(headers: _authHeaders()));
  }

  Future<({String paymentUrl, int orderId})> paytrToken() async {
    final json = await _post('extension/module/mobileapi/paytrToken');
    return (
      paymentUrl: json['payment_url'] as String,
      orderId: json['order_id'] as int,
    );
  }

  // ---------------------------------------------------------------
  // Siparişler
  // ---------------------------------------------------------------

  Future<List<MarketOrderSummary>> orders({int page = 1}) async {
    final json =
        await _get('extension/module/mobileapi/orders', query: {'page': page});
    return (json['orders'] as List<dynamic>? ?? [])
        .map((o) => MarketOrderSummary.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<MarketOrderDetail> orderDetail(int orderId) async {
    final json = await _get('extension/module/mobileapi/orderDetail',
        query: {'order_id': orderId});
    return MarketOrderDetail.fromJson(json['order'] as Map<String, dynamic>);
  }
}
