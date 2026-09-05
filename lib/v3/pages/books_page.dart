import 'package:flutter/material.dart';

import '../data/books.dart';
import '../widgets/book_card.dart';

/// Profil > Kitaplar: tüm kitapların tek listede göründüğü kısayol sayfası.
class V3BooksPage extends StatelessWidget {
  const V3BooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitaplar')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: V3Books.all.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            V3BookShortcut(book: V3Books.all[index]),
      ),
    );
  }
}
