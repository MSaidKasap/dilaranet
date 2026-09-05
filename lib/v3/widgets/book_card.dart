import 'package:flutter/material.dart';

import '../data/books.dart';
import '../theme.dart';

/// Ana sayfa ve Profil > Kitaplar'daki gradyanlı kısayol kartı (v2'deki
/// buton). `compact: true` ile üç kart aynı satıra sığacak şekilde küçülür.
class V3BookShortcut extends StatelessWidget {
  final V3Book book;
  final bool compact;
  const V3BookShortcut({super.key, required this.book, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 30.0 : 36.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: book.open),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
              vertical: compact ? 12 : 14, horizontal: compact ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [V3Colors.primary, Color(0xFF16407F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  book.logoAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: compact ? 16 : 20),
                ),
              ),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
