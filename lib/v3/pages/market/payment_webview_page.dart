import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../theme.dart';

enum MarketPaymentResult { success, failure, cancelled }

/// PayTR'ın güvenli ödeme sayfasını (iframe token URL'i) tam ekran açar.
/// Kart bilgisi hiçbir zaman uygulamaya/OpenCart'a değmez — PayTR'ın kendi
/// sayfasıdır. Yönlendirme `checkout/success` veya `checkout/cart` içerince
/// (bkz. sunucudaki `paytrToken` uç noktasının `merchant_ok_url`/`fail_url`)
/// sonucu tespit edip sayfayı kapatır.
class MarketPaymentWebviewPage extends StatefulWidget {
  final String paymentUrl;

  const MarketPaymentWebviewPage({super.key, required this.paymentUrl});

  @override
  State<MarketPaymentWebviewPage> createState() => _MarketPaymentWebviewPageState();
}

class _MarketPaymentWebviewPageState extends State<MarketPaymentWebviewPage> {
  late final WebViewController _controller;
  bool _finished = false;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p / 100),
        onNavigationRequest: (request) {
          _checkCompletion(request.url);
          return NavigationDecision.navigate;
        },
        onPageStarted: (url) => _checkCompletion(url),
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkCompletion(String url) {
    if (_finished) return;
    if (url.contains('route=checkout/success') ||
        url.contains('route=checkout%2Fsuccess')) {
      _finished = true;
      Navigator.of(context).pop(MarketPaymentResult.success);
    } else if (url.contains('route=checkout/cart') ||
        url.contains('route=checkout%2Fcart')) {
      _finished = true;
      Navigator.of(context).pop(MarketPaymentResult.failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(MarketPaymentResult.cancelled),
        ),
      ),
      body: Column(
        children: [
          if (_progress < 1)
            LinearProgressIndicator(value: _progress, color: V3Colors.primary),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
