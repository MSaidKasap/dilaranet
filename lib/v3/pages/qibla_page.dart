import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';

import '../theme.dart';

/// Kıble pusulası.
///
/// Konum bir kez alınır (canlı akış beklenmez), kıble açısı yerelde hesaplanır,
/// pusula yönü flutter_compass_v2'den gelir ve alçak geçiren filtre ile
/// yumuşatılır.
class V3QiblaPage extends StatefulWidget {
  const V3QiblaPage({super.key});

  @override
  State<V3QiblaPage> createState() => _V3QiblaPageState();
}

class _V3QiblaPageState extends State<V3QiblaPage> {
  // Kâbe koordinatları
  static const _kaabaLat = 21.4224779;
  static const _kaabaLng = 39.8251832;

  double? _qiblaBearing; // kuzeyden saat yönünde derece
  double? _heading; // yumuşatılmış pusula yönü
  bool _hasCompass = true;
  String? _error;
  bool _aligned = false;

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<Position>? _positionSub;
  double _sinAcc = 0;
  double _cosAcc = 1;
  bool _seededHeading = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _compassSub?.cancel();
    _positionSub?.cancel();
    _seededHeading = false;
    setState(() {
      _error = null;
      _qiblaBearing = null;
      _heading = null;
    });

    // 1) Konum izni
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _error = 'Konum servisi kapalı. Kıble için konumu açın.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _error =
            'Konum izni kapalı. Ayarlar > Dilara üzerinden konuma izin verin.');
        return;
      }
      if (perm == LocationPermission.denied) {
        setState(() => _error = 'Konum izni gerekli.');
        return;
      }
    } catch (e) {
      setState(() => _error = 'Konum alınamadı: ${_clean('$e')}');
      return;
    }

    // 2) Hızlı ilk konum: önce son bilinen (anında), yoksa tek seferlik ölçüm.
    Position? pos = await Geolocator.getLastKnownPosition();
    if (pos == null) {
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        pos = null;
      }
    }
    if (pos == null) {
      setState(() =>
          _error = 'Konum alınamadı. Açık bir alanda tekrar deneyin.');
      return;
    }

    if (!mounted) return;
    final first = pos;
    setState(() =>
        _qiblaBearing = _bearingToKaaba(first.latitude, first.longitude));

    // 3) Canlı GPS akışı — konum iyileştikçe kıble açısını güncelle.
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen((p) {
      if (!mounted) return;
      final b = _bearingToKaaba(p.latitude, p.longitude);
      if (_qiblaBearing == null || _deltaDeg(_qiblaBearing!, b).abs() > 0.2) {
        setState(() => _qiblaBearing = b);
      }
    }, onError: (_) {});

    // 4) Pusula akışı
    final stream = FlutterCompass.events;
    if (stream == null) {
      setState(() => _hasCompass = false);
      return;
    }
    _compassSub?.cancel();
    _compassSub = stream.listen(_onCompass);
  }

  void _onCompass(CompassEvent event) {
    final raw = event.heading;
    if (raw == null) return; // kalibrasyon yok
    final rad = raw * math.pi / 180;
    const k = 0.15; // alçak geçiren katsayı
    if (!_seededHeading) {
      _sinAcc = math.sin(rad);
      _cosAcc = math.cos(rad);
      _seededHeading = true;
    } else {
      _sinAcc = _sinAcc * (1 - k) + math.sin(rad) * k;
      _cosAcc = _cosAcc * (1 - k) + math.cos(rad) * k;
    }
    final smoothed = (math.atan2(_sinAcc, _cosAcc) * 180 / math.pi + 360) % 360;

    if (_heading != null && (_deltaDeg(_heading!, smoothed)).abs() < 0.4) return;
    if (!mounted) return;
    setState(() => _heading = smoothed);
  }

  static double _bearingToKaaba(double lat, double lng) {
    final phi1 = lat * math.pi / 180;
    final phi2 = _kaabaLat * math.pi / 180;
    final dLon = (_kaabaLng - lng) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// [-180, 180] aralığında açı farkı
  static double _deltaDeg(double a, double b) {
    var d = (b - a) % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  static String _clean(String e) => e.replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final isPerm = _error!.contains('izin') || _error!.contains('konum') ||
          _error!.contains('Konum');
      return _Message(
        icon: Icons.location_off_outlined,
        text: _error!,
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: _start,
              child: const Text('Tekrar dene',
                  style: TextStyle(color: V3Colors.primary)),
            ),
            if (isPerm)
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Ayarları Aç',
                    style: TextStyle(color: V3Colors.primary)),
              ),
          ],
        ),
      );
    }

    if (_qiblaBearing == null) {
      return const _Message(
        icon: Icons.explore_outlined,
        text: 'Konum alınıyor...',
        showSpinner: true,
      );
    }

    final qibla = _qiblaBearing!;
    final heading = _heading ?? 0;
    final markerAngle = _deltaDeg(heading, qibla); // ekranda kıble işareti açısı
    final toGo = markerAngle.abs();
    final aligned = toGo < 4;
    if (aligned != _aligned) {
      _aligned = aligned;
      if (aligned) HapticFeedback.mediumImpact();
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            aligned
                ? 'Kıble yönündesiniz'
                : 'Kıbleye ${toGo.toStringAsFixed(0)}° kaldı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: aligned ? Colors.green : V3Colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kıble açısı: ${qibla.toStringAsFixed(0)}°'
            '${_heading != null ? '   ·   Pusula: ${heading.toStringAsFixed(0)}°' : ''}',
            style: TextStyle(color: V3Colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Kadran — kuzeye göre döner
                Transform.rotate(
                  angle: -heading * (math.pi / 180),
                  child: CustomPaint(
                    painter: _DialPainter(),
                    size: Size.infinite,
                  ),
                ),
                // Kıble oku (Kâbe işareti)
                Transform.rotate(
                  angle: markerAngle * (math.pi / 180),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.navigation,
                        size: 56,
                        color: aligned ? Colors.green : V3Colors.primary,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: V3Colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (!_hasCompass)
            Text(
              'Bu cihazda pusula sensörü yok. Kıble açısı kuzeye göre yukarıda gösteriliyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: V3Colors.textMuted, fontSize: 12),
            )
          else if (_heading == null)
            Text(
              'Pusula kalibre ediliyor. Telefonu yatay tutup havada 8 çizin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: V3Colors.textMuted, fontSize: 12),
            )
          else
            Text(
              'Oku yukarı (ekranın üstüne) getirene kadar dönün.',
              textAlign: TextAlign.center,
              style: TextStyle(color: V3Colors.textMuted, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = V3Colors.border;
    canvas.drawCircle(center, radius, ring);

    final tick = Paint()..color = V3Colors.textMuted;
    for (var deg = 0; deg < 360; deg += 15) {
      final a = deg * math.pi / 180;
      final outer = center + Offset(math.sin(a), -math.cos(a)) * radius;
      final inner = center +
          Offset(math.sin(a), -math.cos(a)) *
              (radius - (deg % 90 == 0 ? 16 : 8));
      canvas.drawLine(
        inner,
        outer,
        tick..strokeWidth = deg % 90 == 0 ? 3 : 1,
      );
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    const labels = {0: 'K', 90: 'D', 180: 'G', 270: 'B'};
    labels.forEach((deg, label) {
      final a = deg * math.pi / 180;
      tp.text = TextSpan(
        text: label,
        style: TextStyle(
          color: deg == 0 ? V3Colors.primary : V3Colors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
      tp.layout();
      final pos = center +
          Offset(math.sin(a), -math.cos(a)) * (radius - 32) -
          Offset(tp.width / 2, tp.height / 2);
      tp.paint(canvas, pos);
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  final bool showSpinner;
  const _Message({
    required this.icon,
    required this.text,
    this.action,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner)
              const CircularProgressIndicator(color: V3Colors.primary)
            else
              Icon(icon, size: 48, color: V3Colors.textMuted),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: V3Colors.textMuted)),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
