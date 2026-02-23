import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class CdnDownloaderService {
  static const String baseUrl = 'https://cnd.dilara.net';
  static const String versionKey = 'cdn_version';
  static const String currentVersion = '1.0.0'; // Her güncelleme için değiştir

  final Dio _dio = Dio();

  Function(double progress)? onProgress;
  Function(String message)? onStatusUpdate;

  // Ses dosyaları (87 - 120 arası)
  List<int> get audioFiles => List.generate(34, (i) => i + 87);

  // Resim dosyaları (3 - 226 arası)
  List<int> get imageFiles => List.generate(224, (i) => i + 3);
  List<int> get amntimageFiles => List.generate(44, (i) => i + 3);

  /// Ana indirme fonksiyonu
  Future<bool> downloadAllAssets() async {
    try {
      onStatusUpdate?.call('📦 İndirme kontrolü yapılıyor...');

      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString(versionKey);

      if (savedVersion == currentVersion) {
        onStatusUpdate?.call('✅ Dosyalar güncel');
        return true;
      }

      onStatusUpdate?.call('🔄 Dosyalar indiriliyor...');

      await _createDirectories();

      await _downloadAudioFiles();
      await _downloadImageFiles();
      await _downloadSizedImages();
      await _downloadAmntdImages();

      await prefs.setString(versionKey, currentVersion);

      onStatusUpdate?.call('✅ Tüm dosyalar indirildi!');
      return true;
    } catch (e, s) {
      debugPrint('❌ İndirme hatası: $e');
      debugPrint('Stack: $s');
      onStatusUpdate?.call('❌ İndirme hatası: $e');
      return false;
    }
  }

  /// Klasör oluşturma
  /// Klasör oluşturma
  Future<void> _createDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();

    final audioDir = Directory('${appDir.path}/Audio');
    final imgDir = Directory('${appDir.path}/img');
    final sizeDir = Directory('${appDir.path}/img/size');
    final amntDir = Directory('${appDir.path}/img/amnt'); // ✔️ yeni klasör

    if (!await audioDir.exists()) await audioDir.create(recursive: true);
    if (!await imgDir.exists()) await imgDir.create(recursive: true);
    if (!await sizeDir.exists()) await sizeDir.create(recursive: true);
    if (!await amntDir.exists())
      await amntDir.create(recursive: true); // ✔️ eksik olan satır eklendi

    debugPrint('📁 Klasörler oluşturuldu');
  }

  /// SES dosyalarını indir
  Future<void> _downloadAudioFiles() async {
    onStatusUpdate?.call('🎵 Ses dosyaları indiriliyor...');

    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/Audio');

    for (int i = 0; i < audioFiles.length; i++) {
      final fileNumber = audioFiles[i];
      final fileName = '$fileNumber.mp3';
      final filePath = '${audioDir.path}/$fileName';

      if (await File(filePath).exists()) {
        debugPrint('⏭️ $fileName zaten var');
        continue;
      }

      try {
        await _dio.download(
          '$baseUrl/Audio/$fileName',
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100);
              onProgress?.call(progress);
            }
          },
        );

        debugPrint('✅ $fileName indirildi (${i + 1}/${audioFiles.length})');
        onStatusUpdate?.call('🎵 Ses: ${i + 1}/${audioFiles.length}');
      } catch (e) {
        debugPrint('❌ $fileName indirilemedi: $e');
      }
    }
  }

  /// Büyük resimleri indir
  Future<void> _downloadImageFiles() async {
    onStatusUpdate?.call('🖼️ Resimler indiriliyor...');

    final appDir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${appDir.path}/img');

    for (int i = 0; i < imageFiles.length; i++) {
      final fileNumber = imageFiles[i];
      final fileName = 'sevgi ($fileNumber).jpg';
      final filePath = '${imgDir.path}/$fileName';

      if (await File(filePath).exists()) {
        debugPrint('⏭️ $fileName zaten var');
        continue;
      }

      try {
        await _dio.download(
          '$baseUrl/img/$fileName',
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100);
              onProgress?.call(progress);
            }
          },
        );

        debugPrint('✅ $fileName indirildi (${i + 1}/${imageFiles.length})');

        if (i % 10 == 0 || i == imageFiles.length - 1) {
          onStatusUpdate?.call('🖼️ Resim: ${i + 1}/${imageFiles.length}');
        }
      } catch (e) {
        debugPrint('❌ $fileName indirilemedi: $e');
      }
    }
  }

  /// Küçük boy resimleri indir (img/size)
  Future<void> _downloadSizedImages() async {
    onStatusUpdate?.call('🖼️ Küçük boy resimler indiriliyor...');

    final appDir = await getApplicationDocumentsDirectory();
    final sizeDir = Directory('${appDir.path}/img/size');

    for (int i = 0; i < imageFiles.length; i++) {
      final fileNumber = imageFiles[i];
      final fileName = '$fileNumber.jpg';
      final filePath = '${sizeDir.path}/$fileName';

      if (await File(filePath).exists()) {
        debugPrint('⏭️ $fileName (size) zaten var');
        continue;
      }

      try {
        await _dio.download(
          '$baseUrl/img/size/$fileName',
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100);
              onProgress?.call(progress);
            }
          },
        );

        debugPrint(
          '✅ $fileName (size) indirildi (${i + 1}/${imageFiles.length})',
        );

        if (i % 10 == 0 || i == imageFiles.length - 1) {
          onStatusUpdate?.call('🖼️  ${i + 1}/${imageFiles.length}');
        }
      } catch (e) {
        debugPrint('❌ $fileName (size) indirilemedi: $e');
      }
    }
  }

  Future<void> _downloadAmntdImages() async {
    onStatusUpdate?.call('🖼️ Küçük boy resimler indiriliyor...');

    final appDir = await getApplicationDocumentsDirectory();
    final sizeDir = Directory('${appDir.path}/img/amnt');

    for (int i = 0; i < amntimageFiles.length; i++) {
      final fileNumber = amntimageFiles[i];
      final fileName = '$fileNumber.jpg';
      final filePath = '${sizeDir.path}/$fileName';

      if (await File(filePath).exists()) {
        debugPrint('⏭️ $fileName (amnt) zaten var');
        continue;
      }

      try {
        await _dio.download(
          '$baseUrl/img/amnt/$fileName',
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100);
              onProgress?.call(progress);
            }
          },
        );

        debugPrint(
          '✅ $fileName (amnt) indirildi (${i + 1}/${imageFiles.length})',
        );

        if (i % 10 == 0 || i == imageFiles.length - 1) {
          onStatusUpdate?.call('🖼️  ${i + 1}/${imageFiles.length}');
        }
      } catch (e) {
        debugPrint('❌ $fileName (amnt) indirilemedi: $e');
      }
    }
  }

  /// Tek dosya indir
  Future<bool> downloadFile({
    required String url,
    required String savePath,
    Function(double)? onProgress,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress((received / total * 100));
          }
        },
      );
      return true;
    } catch (e) {
      debugPrint('❌ Dosya indirilemedi: $e');
      return false;
    }
  }

  /// Local + CDN yolu kontrol
  Future<String> getFilePath(String relativePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = '${appDir.path}/$relativePath';

    if (await File(localPath).exists()) {
      return localPath;
    }

    return '$baseUrl/$relativePath';
  }

  /// Önbellek temizle
  Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      final audioDir = Directory('${appDir.path}/Audio');
      final imgDir = Directory('${appDir.path}/img');

      if (await audioDir.exists()) await audioDir.delete(recursive: true);
      if (await imgDir.exists()) await imgDir.delete(recursive: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(versionKey);

      debugPrint('🗑️ Önbellek temizlendi');
    } catch (e) {
      debugPrint('❌ Önbellek temizleme hatası: $e');
    }
  }

  /// İndirme durum raporu
  Future<Map<String, dynamic>> checkDownloadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getString(versionKey);

    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/Audio');
    final imgDir = Directory('${appDir.path}/img');
    final sizeDir = Directory('${appDir.path}/img/size');

    int audioCount = 0;
    int imgCount = 0;
    int sizeCount = 0;
    int totimgCount = imgCount + sizeCount;

    if (await audioDir.exists()) audioCount = audioDir.listSync().length;
    if (await imgDir.exists()) imgCount = imgDir.listSync().length;
    if (await sizeDir.exists()) sizeCount = sizeDir.listSync().length;

    return {
      'version': savedVersion ?? 'none',
      'isComplete': savedVersion == currentVersion,
      'audioFiles': audioCount,
      'imageFiles': imgCount,
      'sizeImages': sizeCount,
      'totalAudioFiles': audioFiles.length,
      'totalImageFiles': imageFiles.length,
      'totimgCount': totimgCount,
    };
  }
}
