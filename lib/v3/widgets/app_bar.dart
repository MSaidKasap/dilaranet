import 'package:flutter/material.dart';

import '../theme.dart';
import 'cart_icon_button.dart';

/// news_ui `widgets/nu_appbar.dart` uyarlaması — arama + bildirim aksiyonlu.
/// Soldaki başlık yerine dilara.net logosu kullanılır.
class V3AppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final bool showCart;

  const V3AppBar({
    super.key,
    this.title = 'Dilara',
    this.onSearchTap,
    this.onNotificationsTap,
    this.showCart = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: V3Colors.shadow, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/img/logo.png',
                height: 32,
                fit: BoxFit.contain,
                semanticLabel: title,
              ),
            ),
          ),
          if (onSearchTap != null)
            IconButton(
              onPressed: onSearchTap,
              icon: const Icon(Icons.search, size: 24),
              color: V3Colors.textPrimary,
            ),
          if (onNotificationsTap != null)
            IconButton(
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_none_rounded, size: 24),
              color: V3Colors.textPrimary,
            ),
          if (showCart) const V3CartIconButton(),
        ],
      ),
    );
  }
}
