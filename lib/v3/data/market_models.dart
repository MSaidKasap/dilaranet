library;

import 'package:html_character_entities/html_character_entities.dart';

// Market (dilarayayinlari.com / OpenCart) veri modelleri.

/// OpenCart tutarı "₺180,00" biçiminde, sembol solda döndürür. "₺" glifi
/// bazı fontlarda (ör. PT Serif) yanlış/bozuk çizildiği için Unicode
/// sembolünü hiç kullanmıyoruz; sonuna düz metin "TL" ekliyoruz: "180,00 TL".
String _formatPrice(String raw) {
  final cleaned = raw.replaceAll('₺', '').trim();
  if (cleaned.isEmpty) return raw;
  return '$cleaned TL';
}

String? _formatPriceOrNull(Object? raw) {
  if (raw is! String) return null;
  return _formatPrice(raw);
}

class MarketCategory {
  final int id;
  final String name;
  final String image;
  final List<MarketCategory> children;

  const MarketCategory({
    required this.id,
    required this.name,
    required this.image,
    this.children = const [],
  });

  factory MarketCategory.fromJson(Map<String, dynamic> json) {
    return MarketCategory(
      id: json['category_id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => MarketCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MarketProduct {
  final int id;
  final String name;
  final String image;
  final String price;
  final String? special;
  final int rating;
  final bool inStock;

  const MarketProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.special,
    required this.rating,
    required this.inStock,
  });

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    return MarketProduct(
      id: json['product_id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      price: _formatPrice(json['price'] as String? ?? ''),
      special: json['special'] == false ? null : _formatPriceOrNull(json['special']),
      rating: json['rating'] as int? ?? 0,
      inStock: json['in_stock'] as bool? ?? true,
    );
  }
}

class MarketProductDetail {
  final int id;
  final String name;
  final String descriptionHtml;
  final List<String> images;
  final String price;
  final String? special;
  final int rating;
  final int reviews;
  final bool inStock;
  final String model;

  const MarketProductDetail({
    required this.id,
    required this.name,
    required this.descriptionHtml,
    required this.images,
    required this.price,
    required this.special,
    required this.rating,
    required this.reviews,
    required this.inStock,
    required this.model,
  });

  factory MarketProductDetail.fromJson(Map<String, dynamic> json) {
    return MarketProductDetail(
      id: json['product_id'] as int,
      name: json['name'] as String? ?? '',
      // mobileapi.php ürün açıklamasını çift HTML-encode ediyor (ör.
      // "&lt;p&gt;...&lt;/p&gt;"); önce çözmezsek etiketler metin olarak görünür.
      descriptionHtml:
          HtmlCharacterEntities.decode(json['description'] as String? ?? ''),
      images: (json['images'] as List<dynamic>? ?? []).cast<String>(),
      price: _formatPrice(json['price'] as String? ?? ''),
      special: json['special'] == false ? null : _formatPriceOrNull(json['special']),
      rating: json['rating'] as int? ?? 0,
      reviews: json['reviews'] as int? ?? 0,
      inStock: json['in_stock'] as bool? ?? true,
      model: json['model'] as String? ?? '',
    );
  }
}

class MarketCustomer {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String telephone;

  const MarketCustomer({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.telephone,
  });

  String get fullName => '$firstname $lastname'.trim();

  factory MarketCustomer.fromJson(Map<String, dynamic> json) {
    return MarketCustomer(
      id: json['customer_id'] as int,
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
    );
  }
}

class MarketCartItem {
  final String cartId;
  final int productId;
  final String name;
  final String image;
  final int quantity;
  final String price;
  final String total;
  final bool stock;

  const MarketCartItem({
    required this.cartId,
    required this.productId,
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
    required this.total,
    required this.stock,
  });

  factory MarketCartItem.fromJson(Map<String, dynamic> json) {
    return MarketCartItem(
      cartId: '${json['cart_id']}',
      productId: json['product_id'] as int,
      name: json['name'] as String? ?? '',
      image: json['image'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: _formatPrice(json['price'] as String? ?? ''),
      total: _formatPrice(json['total'] as String? ?? ''),
      stock: json['stock'] as bool? ?? true,
    );
  }
}

class MarketTotalLine {
  final String title;
  final String text;

  const MarketTotalLine({required this.title, required this.text});

  factory MarketTotalLine.fromJson(Map<String, dynamic> json) {
    return MarketTotalLine(
      title: json['title'] as String? ?? '',
      text: _formatPrice(json['text'] as String? ?? ''),
    );
  }
}

class MarketCart {
  final List<MarketCartItem> items;
  final List<MarketTotalLine> totals;
  final bool hasStock;
  final int itemCount;

  const MarketCart({
    required this.items,
    required this.totals,
    required this.hasStock,
    required this.itemCount,
  });

  bool get isEmpty => items.isEmpty;

  factory MarketCart.fromJson(Map<String, dynamic> json) {
    return MarketCart(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => MarketCartItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: (json['totals'] as List<dynamic>? ?? [])
          .map((e) => MarketTotalLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasStock: json['has_stock'] as bool? ?? true,
      itemCount: json['item_count'] as int? ?? 0,
    );
  }
}

class MarketShippingQuote {
  final String code;
  final String title;
  final String text;

  const MarketShippingQuote({
    required this.code,
    required this.title,
    required this.text,
  });
}

/// `shippingQuotes` uç noktasının ham JSON'unu düz bir listeye çevirir.
List<MarketShippingQuote> parseShippingQuotes(Map<String, dynamic> json) {
  final out = <MarketShippingQuote>[];
  final methods = json['shipping_methods'] as Map<String, dynamic>? ?? {};
  for (final entry in methods.entries) {
    final method = entry.value as Map<String, dynamic>;
    final quotes = method['quote'] as Map<String, dynamic>? ?? {};
    for (final q in quotes.entries) {
      final quote = q.value as Map<String, dynamic>;
      out.add(MarketShippingQuote(
        code: quote['code'] as String? ?? '${entry.key}.${q.key}',
        title: quote['title'] as String? ?? method['title'] as String? ?? '',
        text: _formatPrice(quote['text'] as String? ?? ''),
      ));
    }
  }
  return out;
}

class MarketOrderSummary {
  final int id;
  final String status;
  final String date;
  final String total;

  const MarketOrderSummary({
    required this.id,
    required this.status,
    required this.date,
    required this.total,
  });

  factory MarketOrderSummary.fromJson(Map<String, dynamic> json) {
    return MarketOrderSummary(
      id: json['order_id'] as int,
      status: json['status'] as String? ?? '',
      date: json['date'] as String? ?? '',
      total: _formatPrice(json['total'] as String? ?? ''),
    );
  }
}

class MarketOrderProductLine {
  final String name;
  final String model;
  final int quantity;
  final String price;
  final String total;

  const MarketOrderProductLine({
    required this.name,
    required this.model,
    required this.quantity,
    required this.price,
    required this.total,
  });

  factory MarketOrderProductLine.fromJson(Map<String, dynamic> json) {
    return MarketOrderProductLine(
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: _formatPrice(json['price'] as String? ?? ''),
      total: _formatPrice(json['total'] as String? ?? ''),
    );
  }
}

class MarketOrderHistoryLine {
  final String status;
  final String comment;
  final String date;

  const MarketOrderHistoryLine({
    required this.status,
    required this.comment,
    required this.date,
  });

  factory MarketOrderHistoryLine.fromJson(Map<String, dynamic> json) {
    return MarketOrderHistoryLine(
      status: json['status'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}

class MarketOrderDetail {
  final int id;
  final String status;
  final String date;
  final List<MarketOrderProductLine> products;
  final List<MarketTotalLine> totals;
  final List<MarketOrderHistoryLine> histories;
  final String shippingAddress;

  const MarketOrderDetail({
    required this.id,
    required this.status,
    required this.date,
    required this.products,
    required this.totals,
    required this.histories,
    required this.shippingAddress,
  });

  factory MarketOrderDetail.fromJson(Map<String, dynamic> json) {
    return MarketOrderDetail(
      id: json['order_id'] as int,
      status: json['status'] as String? ?? '',
      date: json['date'] as String? ?? '',
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => MarketOrderProductLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      totals: (json['totals'] as List<dynamic>? ?? [])
          .map((e) => MarketTotalLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      histories: (json['histories'] as List<dynamic>? ?? [])
          .map((e) => MarketOrderHistoryLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingAddress: json['shipping_address'] as String? ?? '',
    );
  }
}

/// Hesabın "Adreslerim" defterindeki bir kayıt. `addressId` null ise henüz
/// sunucuya kaydedilmemiş (yeni ekleniyor) demektir.
class MarketAddress {
  final int? addressId;
  final String firstname;
  final String lastname;
  final String address1;
  final String address2;
  final String city;
  final String postcode;
  final int countryId;
  final int zoneId;
  final bool isDefault;

  const MarketAddress({
    this.addressId,
    required this.firstname,
    required this.lastname,
    required this.address1,
    this.address2 = '',
    required this.city,
    required this.postcode,
    this.countryId = 215, // Türkiye
    required this.zoneId,
    this.isDefault = false,
  });

  /// `checkout/shipping_address/save` ve `checkout/payment_address/save`
  /// uç noktalarının beklediği form alanları.
  Map<String, String> toFormData() => {
        'firstname': firstname,
        'lastname': lastname,
        'address_1': address1,
        'address_2': address2,
        'city': city,
        'postcode': postcode,
        'country_id': '$countryId',
        'zone_id': '$zoneId',
      };

  /// mobileapi `addressSave` uç noktasına gönderilecek gövde.
  Map<String, dynamic> toRequestData() => {
        if (addressId != null) 'address_id': addressId,
        'firstname': firstname,
        'lastname': lastname,
        'address_1': address1,
        'address_2': address2,
        'city': city,
        'postcode': postcode,
        'country_id': countryId,
        'zone_id': zoneId,
      };

  factory MarketAddress.fromJson(Map<String, dynamic> json) => MarketAddress(
        addressId: json['address_id'] as int?,
        firstname: json['firstname'] as String? ?? '',
        lastname: json['lastname'] as String? ?? '',
        address1: json['address_1'] as String? ?? '',
        address2: json['address_2'] as String? ?? '',
        city: json['city'] as String? ?? '',
        postcode: json['postcode'] as String? ?? '',
        countryId: json['country_id'] as int? ?? 215,
        zoneId: json['zone_id'] as int? ?? 0,
        isDefault: json['default'] as bool? ?? false,
      );
}
