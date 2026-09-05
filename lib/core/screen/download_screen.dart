import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:Dilara/services/cdn_downloader_service.dart';

class DownloadScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const DownloadScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with SingleTickerProviderStateMixin {
  final CdnDownloaderService _downloader = CdnDownloaderService();
  final Connectivity _connectivity = Connectivity();

  String _statusMessage = "Hazırlanıyor...";
  double _fileProgress = 0;
  bool _isDownloading = false;
  bool _isComplete = false;
  bool _hasError = false;
  bool _isWifiConnected = false;
  bool _isCheckingConnection = true;
  bool _userApprovedMobileData = false;

  @override
  void initState() {
    super.initState();
    _checkWifiAndStart();
  }

  Future<void> _checkWifiAndStart() async {
    setState(() {
      _isCheckingConnection = true;
      _statusMessage = "İnternet bağlantısı kontrol ediliyor...";
    });

    final connectivityResult = await _connectivity.checkConnectivity();
    final isWifi = connectivityResult.contains(ConnectivityResult.wifi);

    setState(() {
      _isWifiConnected = isWifi;
      _isCheckingConnection = false;
    });

    if (isWifi) {
      _startDownload();
    } else {
      setState(() {
        _statusMessage = "Mobil veri ile indirmek istiyor musunuz?";
      });
    }
  }

  void _showMobileDataDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text("Mobil Veri Uyarısı"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "WiFi bağlantısı bulunamadı.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                "İndirme işlemi büyük miktarda veri kullanabilir. Mobil veri ile devam etmek istiyor musunuz?",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Tahmini veri kullanımı: ~50-100 MB",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _statusMessage = "İndirme iptal edildi. WiFi'ye bağlanın.";
                });
              },
              child: const Text(
                "İptal",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _userApprovedMobileData = true;
                });
                _startDownload();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Devam Et",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
    });

    _downloader.onStatusUpdate = (message) {
      // Dosya adı veya numarası varsa filtrele
      if (message.contains(".mp3") || message.contains("audio")) {
        message = "Ses dosyaları indiriliyor...";
      } else if (message.contains(".png") ||
          message.contains(".jpg") ||
          message.contains("image")) {
        message = "Resimler indiriliyor...";
      }

      setState(() => _statusMessage = message);
    };

    _downloader.onProgress = (progress) {
      setState(() => _fileProgress = progress);
    };

    final success = await _downloader.downloadAllAssets();

    setState(() {
      _isDownloading = false;
      _isComplete = success;
      _hasError = !success;
    });

    if (success) {
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.green],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- Logo ---
              Image.asset('assets/img/logo.png', width: 400, height: 250),

              const SizedBox(height: 20),

              // Başlık
              Text(
                _isComplete
                    ? "İndirildi!"
                    : _hasError
                    ? "Hata Oluştu"
                    : !_isWifiConnected && !_isCheckingConnection
                    ? "WiFi Gerekli"
                    : "İndiriliyor...",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Alt yazı
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),

              const SizedBox(height: 40),

              // --- WiFi Uyarısı ---
              if (!_isWifiConnected &&
                  !_isCheckingConnection &&
                  !_isComplete &&
                  !_userApprovedMobileData) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.signal_cellular_alt,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Mobil Veri Bağlantısı Tespit Edildi",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "İndirme işlemi için WiFi önerilir. Mobil veri ile devam etmek isterseniz onay vermeniz gerekir.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _checkWifiAndStart,
                      icon: const Icon(Icons.wifi),
                      label: const Text("WiFi Kontrol"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _showMobileDataDialog,
                      icon: const Icon(Icons.download),
                      label: const Text("Yine de İndir"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // --- Progress Bar ---
              if (_isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.3),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width:
                            (MediaQuery.of(context).size.width - 64) *
                            (_fileProgress / 100),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "%${_fileProgress.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],

              // --- Hata Butonu ---
              if (_hasError && _isWifiConnected) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tekrar Dene"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 50),

              // Bilgi kutusu
              if (_isWifiConnected || _isComplete || _userApprovedMobileData)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isWifiConnected
                            ? Icons.wifi
                            : Icons.signal_cellular_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isWifiConnected
                              ? "İçerik ilk açılışta indirilecek ve offline kullanılabilir olacaktır."
                              : "Mobil veri ile indiriliyor. İçerik offline kullanılabilir olacaktır.",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
