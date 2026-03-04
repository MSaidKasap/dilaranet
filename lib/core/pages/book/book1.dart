// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:path_provider/path_provider.dart';
import 'contents.dart';

class ImageViewerPage extends StatefulWidget {
  final String title;
  final int initialImageIndex;

  const ImageViewerPage(this.title, this.initialImageIndex, {super.key});

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controlsAnimationController;
  bool _showControls = true;
  late ValueNotifier<int> _currentPageNotifier;

  @override
  void initState() {
    super.initState();
    _currentPageNotifier = ValueNotifier<int>(widget.initialImageIndex);
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsAnimationController.forward();
  }

  @override
  void dispose() {
    _controlsAnimationController.dispose();
    _currentPageNotifier.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controlsAnimationController.forward();
      } else {
        _controlsAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _controlsAnimationController,
          builder: (context, child) {
            return SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controlsAnimationController,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.7),
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: ValueListenableBuilder<int>(
                  valueListenable: _currentPageNotifier,
                  builder: (context, currentPage, child) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            '${currentPage + 1} / 224',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _showControls ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: _toggleControls,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: GestureDetector(
        onTap: _toggleControls,
        child: ImageViewerCarousel(
          widget.initialImageIndex,
          showControls: _showControls,
          controlsAnimation: _controlsAnimationController,
          onPageChanged: (page) {
            _currentPageNotifier.value = page;
          },
        ),
      ),
    );
  }
}

class ImageViewerCarousel extends StatefulWidget {
  final int initialImageIndex;
  final bool showControls;
  final AnimationController controlsAnimation;
  final Function(int) onPageChanged;

  const ImageViewerCarousel(
    this.initialImageIndex, {
    super.key,
    required this.showControls,
    required this.controlsAnimation,
    required this.onPageChanged,
  });

  @override
  _ImageViewerCarouselState createState() => _ImageViewerCarouselState();
}

class _ImageViewerCarouselState extends State<ImageViewerCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AssetsAudioPlayer assetsAudioPlayer;
  int currentPage = 0;
  late AnimationController _audioButtonController;
  late Animation<double> _audioButtonScale;
  bool _isLoadingAudio = false;
  bool _autoPlayMode = false;

  // ValueNotifier ile state yönetimi
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> _currentPositionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<Duration> _totalDurationNotifier =
      ValueNotifier<Duration>(Duration.zero);

  final Set<int> imagesWithAudio = {
    87,
    88,
    89,
    90,
    91,
    92,
    93,
    94,
    95,
    96,
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    109,
    110,
    111,
    112,
    113,
    114,
    115,
    116,
    117,
    118,
    119,
    120,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialImageIndex);
    currentPage = widget.initialImageIndex;

    assetsAudioPlayer = AssetsAudioPlayer.newPlayer();

    _audioButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _audioButtonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _audioButtonController, curve: Curves.easeInOut),
    );

    assetsAudioPlayer.isPlaying.listen((playing) {
      if (mounted) {
        _isPlayingNotifier.value = playing;
      }
    });

    assetsAudioPlayer.currentPosition.listen((position) {
      if (mounted) {
        _currentPositionNotifier.value = position;
      }
    });

    assetsAudioPlayer.current.listen((playingAudio) {
      if (playingAudio != null && mounted) {
        _totalDurationNotifier.value = playingAudio.audio.duration;
      }
    });

    // Ses bittiğinde otomatik sayfa geçişi
    assetsAudioPlayer.playlistAudioFinished.listen((finished) {
      if (_autoPlayMode && mounted) {
        print('🎵 Ses bitti, otomatik modda sonraki sayfaya geçiliyor...');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && currentPage < 223) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _audioButtonController.dispose();
    assetsAudioPlayer.dispose();
    _isPlayingNotifier.dispose();
    _currentPositionNotifier.dispose();
    _totalDurationNotifier.dispose();
    super.dispose();
  }

  Future<void> playAudio(int imageNumber) async {
    if (_isLoadingAudio) return;

    setState(() {
      _isLoadingAudio = true;
    });

    try {
      try {
        await assetsAudioPlayer.stop();
      } catch (e) {
        print('⚠️ Stop hatası (normal): $e');
      }

      await Future.delayed(const Duration(milliseconds: 200));

      final appDir = await getApplicationDocumentsDirectory();
      final audioPath = '${appDir.path}/Audio/$imageNumber.mp3';
      final audioFile = File(audioPath);

      if (await audioFile.exists()) {
        final fileSize = await audioFile.length();
        print('✅ Ses dosyası bulundu: $audioPath (${fileSize} bytes)');

        if (fileSize < 1000) {
          throw Exception('Ses dosyası çok küçük, bozuk olabilir');
        }

        print('🎵 Local ses çalınıyor...');

        await assetsAudioPlayer
            .open(
              Audio.file(audioPath),
              autoStart: true,
              showNotification: true,
              loopMode: LoopMode.none,
              respectSilentMode: false,
              notificationSettings: const NotificationSettings(
                playPauseEnabled: true,
                seekBarEnabled: true,
                nextEnabled: false,
                prevEnabled: false,
              ),
              playInBackground: PlayInBackground.enabled,
            )
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                throw Exception('Ses yükleme zaman aşımı');
              },
            );

        print('✅ Ses başarıyla başlatıldı');

        _audioButtonController.forward().then((_) {
          if (mounted) _audioButtonController.reverse();
        });
        HapticFeedback.lightImpact();
      } else {
        final cdnUrl = 'https://cdn.dilara.net/Audio/$imageNumber.mp3';
        print('🌐 Local yok, CDN\'den ses çalınıyor: $cdnUrl');

        await assetsAudioPlayer
            .open(
              Audio.network(
                cdnUrl,
                metas: Metas(
                  title: 'Sevgi Bağı - Sayfa $imageNumber',
                  artist: 'Hizb-i Azam',
                ),
              ),
              autoStart: true,
              showNotification: true,
              loopMode: LoopMode.none,
              respectSilentMode: false,
              notificationSettings: const NotificationSettings(
                playPauseEnabled: true,
                seekBarEnabled: true,
                nextEnabled: false,
                prevEnabled: false,
              ),
              playInBackground: PlayInBackground.enabled,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('CDN ses yükleme zaman aşımı');
              },
            );

        print('✅ CDN\'den ses başarıyla başlatıldı');

        _audioButtonController.forward().then((_) {
          if (mounted) _audioButtonController.reverse();
        });
        HapticFeedback.lightImpact();
      }
    } catch (e, stackTrace) {
      print('❌ Ses çalma hatası: $e');
      print('📍 Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses dosyası yüklenemedi: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAudio = false;
        });
      }
    }
  }

  Future<void> stopAudio({bool disableAutoPlay = true}) async {
    try {
      await assetsAudioPlayer.stop();
    } catch (_) {}

    HapticFeedback.lightImpact();

    // ✅ sadece kullanıcı manuel stop edince kapat
    if (disableAutoPlay && _autoPlayMode) {
      setState(() {
        _autoPlayMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.repeat_one, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Otomatik çalma KAPANDI',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  void toggleAudio(int imageNumber) {
    if (_isLoadingAudio) return;

    if (_isPlayingNotifier.value) {
      stopAudio(disableAutoPlay: true); // ✅ manuel stop
    } else {
      playAudio(imageNumber);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<String> _getImagePath(String fileName) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/img/$fileName';

      if (await File(localPath).exists()) {
        return localPath;
      }

      print('❌ Resim local\'de bulunamadı, CDN kullanılıyor: $fileName');
      return 'https://cdn.dilara.net/img/$fileName';
    } catch (e) {
      print('❌ Resim yolu hatası: $e');
      return 'https://cdn.dilara.net/img/$fileName';
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.white54, size: 64),
          SizedBox(height: 16),
          Text(
            'Resim yüklenemedi',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) async {
            await stopAudio(
              disableAutoPlay: false,
            ); // ✅ sadece sesi kes, autoPlay kalsın

            setState(() {
              currentPage = index;
            });

            widget.onPageChanged(index);

            final imageNumber = index + 3;
            if (_autoPlayMode && imagesWithAudio.contains(imageNumber)) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) playAudio(imageNumber);
              });
            }
          },
          itemCount: 224,
          itemBuilder: (context, index) {
            final imageNumber = index + 3;
            final imageName = 'sevgi ($imageNumber).jpg';

            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    Colors.black, // Ortada tam siyah
                    Colors.grey[900]!,
                    Colors.grey[800]!,
                    Colors.grey[600]!,
                    Colors.grey[400]!, // Kenarlarda daha açık
                  ],
                  stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: FutureBuilder<String>(
                        future: _getImagePath(imageName),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError || !snapshot.hasData) {
                            return _buildErrorWidget();
                          }

                          final imagePath = snapshot.data!;
                          final isLocal = !imagePath.startsWith('http');

                          if (isLocal) {
                            return Image.file(
                              File(imagePath),
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildErrorWidget();
                              },
                            );
                          }

                          return Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildErrorWidget();
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // Sağ üstteki sayfa numarası kaldırıldı - artık AppBar'da
                ],
              ),
            );
          },
        ),

        // ✅ TEK BİRLEŞİK KONTROL PANELİ
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: AnimatedBuilder(
            animation: widget.controlsAnimation,
            builder: (context, child) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: widget.controlsAnimation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: _buildUnifiedControls(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedControls() {
    final imageNumber = currentPage + 3;
    final hasAudio = imagesWithAudio.contains(imageNumber);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ SLIDER - Sadece ses çalarken göster
          if (hasAudio)
            ValueListenableBuilder<bool>(
              valueListenable: _isPlayingNotifier,
              builder: (context, isPlayingValue, child) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: _totalDurationNotifier,
                  builder: (context, totalDurationValue, child) {
                    if (isPlayingValue && totalDurationValue.inSeconds > 0) {
                      return ValueListenableBuilder<Duration>(
                        valueListenable: _currentPositionNotifier,
                        builder: (context, currentPositionValue, child) {
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  inactiveTrackColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  thumbColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 5,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10,
                                  ),
                                  trackHeight: 2.5,
                                ),
                                child: Slider(
                                  value: currentPositionValue.inSeconds
                                      .toDouble()
                                      .clamp(
                                        0.0,
                                        totalDurationValue.inSeconds.toDouble(),
                                      ),
                                  max: totalDurationValue.inSeconds.toDouble(),
                                  onChanged: (value) {
                                    assetsAudioPlayer.seek(
                                      Duration(seconds: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(currentPositionValue),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(totalDurationValue),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),

          // ✅ ANA KONTROLLER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Geri butonu
              _buildControlButton(
                icon: Icons.skip_previous,
                onPressed: currentPage > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                size: 44,
              ),

              // Otomatik çalma - Sadece ses varsa
              if (hasAudio && widget.showControls)
                _buildControlButton(
                  icon: _autoPlayMode ? Icons.autorenew : Icons.repeat_one,
                  onPressed: () {
                    setState(() {
                      _autoPlayMode = !_autoPlayMode;
                    });
                    HapticFeedback.mediumImpact();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(
                              _autoPlayMode
                                  ? Icons.autorenew
                                  : Icons.repeat_one,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _autoPlayMode
                                  ? 'Otomatik çalma AÇIK'
                                  : 'Otomatik çalma KAPALI',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.only(
                          bottom: 100,
                          left: 20,
                          right: 20,
                        ),
                        backgroundColor: _autoPlayMode
                            ? Colors.green[700]
                            : Colors.grey[800],
                      ),
                    );

                    if (_autoPlayMode && hasAudio) {
                      playAudio(imageNumber);
                    }
                  },
                  size: 44,
                  isActive: _autoPlayMode,
                  activeColor: Colors.green,
                ),

              // Play/Pause - Sadece ses varsa
              if (hasAudio && widget.showControls)
                ValueListenableBuilder<bool>(
                  valueListenable: _isPlayingNotifier,
                  builder: (context, isPlayingValue, child) {
                    return AnimatedBuilder(
                      animation: _audioButtonScale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _audioButtonScale.value,
                          child: _buildControlButton(
                            icon: _isLoadingAudio
                                ? Icons.more_horiz
                                : (isPlayingValue
                                      ? Icons.pause
                                      : Icons.play_arrow),
                            onPressed: _isLoadingAudio
                                ? null
                                : () => toggleAudio(imageNumber),
                            size: 52,
                            isLoading: _isLoadingAudio,
                            isActive: isPlayingValue,
                            activeColor: Colors.red,
                          ),
                        );
                      },
                    );
                  },
                ),

              // Sayfa numarası (ortada)
              if (!hasAudio || !widget.showControls)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Sayfa ${currentPage + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              // İleri butonu
              _buildControlButton(
                icon: Icons.skip_next,
                onPressed: currentPage < 223
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
                size: 44,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    double size = 44,
    bool isLoading = false,
    bool isActive = false,
    Color? activeColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isActive && activeColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [activeColor.withOpacity(0.8), activeColor],
              )
            : null,
        color: isActive && activeColor == null
            ? Theme.of(context).colorScheme.primary
            : (onPressed != null
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: (activeColor ?? Theme.of(context).colorScheme.primary)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: size * 0.5,
                    height: size * 0.5,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Icon(
                  icon,
                  color: onPressed != null
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                  size: size * 0.5,
                ),
        ),
      ),
    );
  }
}

// ContentPage - Değişiklik yok
class ContentPage extends StatefulWidget {
  const ContentPage({Key? key}) : super(key: key);

  @override
  _ContentPageState createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showFullBook = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Sevgi Bağı',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _showFullBook
            ? _buildFullBook()
            : _buildTableOfContents(context),
      ),
    );
  }

  Widget _buildTableOfContents(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.auto_stories, size: 48, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'İÇİNDEKİLER',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hizb-i A\'zam Sesli Kitap',
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = items[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ImageViewerPage(item['text'], item['extraCount']),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              item['count'].toString(),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item['text'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }, childCount: items.length),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildFullBook() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 224,
      itemBuilder: (context, index) {
        final imageNumber = index + 3;
        final imageName = 'sevgi ($imageNumber).jpg';

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerPage(
                      'Sevgi Bağı - Sayfa $imageNumber',
                      index,
                    ),
                  ),
                );
              },
              child: Image.asset(
                'assets/img/$imageName',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48),
                        SizedBox(height: 8),
                        Text('Resim yüklenemedi'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
    );
  }
}
