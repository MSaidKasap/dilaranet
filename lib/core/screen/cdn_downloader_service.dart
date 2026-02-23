import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CdnDownloaderService {
  static const String baseUrl = 'https://cnd.dilara.net';
  static const String versionKey = 'cdn_version';
  static const String currentVersion = '1.0.2';

  final Dio _dio = Dio();

  /// UI callback’ler
  Function(String message)? onStatus;
  Function(double progress)? onOverallProgress;

  /// SES (87–120)
  List<int> get audioFiles => List.generate(34, (i) => i + 87);

  /// SEVGİ (1–224)
  List<int> get sevgiImages => List.generate(224, (i) => i + 1);

  /// SIZE (3–226)
  List<int> get sizeImages => List.generate(300, (i) => i + 3);

  /// AMNT (1–50)
  List<int> get amntImages => List.generate(45, (i) => i + 1);

  /// ANA İNDİRME
  Future<bool> downloadAllAssets() async {
    try {
      onStatus?.call("🔍 Dosya kontrol ediliyor...");

      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(versionKey);

      if (savedVersion == currentVersion) {
        onStatus?.call("✅ Dosyalar güncel");
        return true;
      }

      await _createDirectories();
      onStatus?.call("📥 İndirme başlatılıyor...");

      // TOPLAM ADET
      final totalItems =
          audioFiles.length +
          sevgiImages.length +
          sizeImages.length +
          amntImages.length;

      int downloaded = 0;

      void updateProgress() {
        double percent = downloaded / totalItems * 100;
        onOverallProgress?.call(percent);
      }

      /// 1) SES
      onStatus?.call("🎧 Ses dosyaları indiriliyor...");
      for (final i in audioFiles) {
        await _safeDownload("$baseUrl/Audio/$i.mp3", "Audio/$i.mp3");
        downloaded++;
        updateProgress();
      }

      /// 2) SEVGİ
      onStatus?.call("📘 Sevgi resimleri indiriliyor...");
      for (final i in sevgiImages) {
        await _safeDownload("$baseUrl/img/$i.jpg", "img/$i.jpg");
        downloaded++;
        updateProgress();
      }

      /// 3) SIZE
      onStatus?.call("📗 Size resimleri indiriliyor...");
      for (final i in sizeImages) {
        await _safeDownload("$baseUrl/img/size/$i.jpg", "img/size/$i.jpg");
        downloaded++;
        updateProgress();
      }

      /// 4) AMNT — (EKLENEN KISIM)
      onStatus?.call("🖼️ Amnt resimleri indiriliyor...");
      for (final i in amntImages) {
        await _safeDownload("$baseUrl/img/amnt/$i.jpg", "img/amnt/$i.jpg");
        downloaded++;
        updateProgress();
      }

      await prefs.setString(versionKey, currentVersion);

      onStatus?.call("🌟 Tüm dosyalar indirildi!");
      return true;
    } catch (e, s) {
      debugPrint("❌ İndirme hatası: $e\n$s");
      onStatus?.call("❌ Bir hata oluştu!");
      return false;
    }
  }

  /// 📁 KLASÖRLER
  Future<void> _createDirectories() async {
    final app = await getApplicationDocumentsDirectory();

    final List<Directory> dirs = [
      Directory("${app.path}/Audio"),
      Directory("${app.path}/img"),
      Directory("${app.path}/img/size"),
      Directory("${app.path}/img/amnt"), // ✔️ AMNT KLÖSÖRÜ EKLENDİ
    ];

    for (final d in dirs) {
      if (!d.existsSync()) d.createSync(recursive: true);
    }

    debugPrint("📁 Gerekli klasörler oluşturuldu");
  }

  /// 📥 GÜVENLİ İNDİRME
  Future<void> _safeDownload(String url, String relativePath) async {
    try {
      final app = await getApplicationDocumentsDirectory();
      final file = File("${app.path}/$relativePath");

      if (file.existsSync()) return;

      await _dio.download(url, file.path);
    } catch (_) {
      debugPrint("⚠️ Dosya indirilemedi: $url");
    }
  }

  /// 📊 DURUM KONTROLÜ
  Future<Map<String, dynamic>> checkDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString(versionKey);

    final app = await getApplicationDocumentsDirectory();

    int audioCount = Directory("${app.path}/Audio").existsSync()
        ? Directory("${app.path}/Audio").listSync().length
        : 0;

    int sevgiCount = Directory("${app.path}/img").existsSync()
        ? Directory("${app.path}/img").listSync().length
        : 0;

    int sizeCount = Directory("${app.path}/img/size").existsSync()
        ? Directory("${app.path}/img/size").listSync().length
        : 0;

    int amntCount = Directory("${app.path}/img/amnt").existsSync()
        ? Directory("${app.path}/img/amnt").listSync().length
        : 0;

    return {
      "version": savedVersion ?? "none",
      "isComplete": savedVersion == currentVersion,

      "audio": audioCount,
      "sevgi": sevgiCount,
      "size": sizeCount,
      "amnt": amntCount,

      "totalAudio": audioFiles.length,
      "totalSevgi": sevgiImages.length,
      "totalSize": sizeImages.length,
      "totalAmnt": amntImages.length,
    };
  }
}
