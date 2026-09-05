import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// V3 tasarım sistemi.
///
/// Kaynak: OLayemii/flutter-ui-kits -> news_ui (utils/constants.dart)
/// Modern Flutter'a uyarlandı, eski `lib/core` yapısına dokunulmadı.
class V3Colors {
  // dilara.net logosundaki mavi.
  static const Color primary = Color(0xFF1D55A9);
  static const Color scaffold = Colors.white;
  static const Color surface = Color.fromRGBO(245, 246, 250, 1);
  static const Color border = Color.fromRGBO(233, 233, 233, 1);
  static const Color textPrimary = Color.fromRGBO(28, 28, 28, 1);
  static const Color textMuted = Color.fromRGBO(139, 144, 165, 1);
  static const Color shadow = Color.fromRGBO(169, 176, 185, 0.42);
}

class V3Theme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: V3Colors.primary,
        primary: V3Colors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: V3Colors.scaffold,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: GoogleFonts.ptSerifTextTheme(base.textTheme).apply(
        bodyColor: V3Colors.textPrimary,
        displayColor: V3Colors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: V3Colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }

  /// Sistem karanlık moddayken kullanılır (bkz. `app.dart`'taki
  /// `themeMode: ThemeMode.system`). `V3Colors` sabitleri hâlâ açık tema
  /// için tasarlandığından (bkz. dosya başı yorumu), ekranlardaki bazı kart/
  /// kenarlık renkleri koyu modda da açık kalabilir — `Scaffold`/`AppBar`
  /// arka planı ve varsayılan metin/simge renkleri doğru şekilde koyulaşır.
  static ThemeData dark() {
    const background = Color(0xFF121212);
    const surface = Color(0xFF1C1C1E);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: V3Colors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      textTheme: GoogleFonts.ptSerifTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardColor: surface,
      dividerColor: Colors.white24,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
      ),
    );
  }
}

/// news_ui'daki ScreenUtil `.setHeight / .setWidth` çağrılarının
/// hafif karşılığı — tasarım referansı 375 x 812.
class V3Size {
  static double h(BuildContext context, double value) {
    final height = MediaQuery.of(context).size.height;
    return value / 812.0 * height;
  }

  static double w(BuildContext context, double value) {
    final width = MediaQuery.of(context).size.width;
    return value / 375.0 * width;
  }
}
