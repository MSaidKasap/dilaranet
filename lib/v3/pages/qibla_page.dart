import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:geolocator/geolocator.dart';

import '../theme.dart';

/// Kıble pusulası.
///
/// Akış: **önce pusula kalibrasyonu**, sonra **taze/net konum** ölçümü.
///
/// - Kalibrasyon: pusula akışı başlatılır, `CompassEvent.accuracy` izlenir;
///   yeterli doğruluk ~1.4 sn boyunca sabit kalınca konuma geçilir (ya da
///   kullanıcı 8 sn sonra "atla" der).
/// - Konum: son bilinen değil, `getCurrentPosition(high)` ile taze konum
///   alınır; başarısız olursa son bilinen konuma (işaretli) düşülür.
/// - Gerçek kuzey: iOS `flutter_compass_v2` zaten `trueHeading` döndürür.
///   Android manyetik kuzey döndürdüğü için native `GeomagneticField` ile
///   sapma (declination) alınıp yöne eklenir — `net.dilara.social/widget`
///   kanalındaki `getMagneticDeclination`.
class V3QiblaPage extends StatefulWidget {
  const V3QiblaPage({super.key});

  @override
  State<V3QiblaPage> createState() => _V3QiblaPageState();
}

enum _Phase { calibrating, locating, ready, error }

class _V3QiblaPageState extends State<V3QiblaPage>
    with SingleTickerProviderStateMixin {
  // Kâbe koordinatları
  static const _kaabaLat = 21.4224779;
  static const _kaabaLng = 39.8251832;

  static const _channel = MethodChannel('net.dilara.social/widget');
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  _Phase _phase = _Phase.calibrating;
  String? _error;
  bool _errorIsPermission = false;
  bool _hasCompass = true;

  // Pusula
  StreamSubscription<CompassEvent>? _compassSub;
  double? _smoothHeading; // yumuşatılmış — Android'de manyetik kuzeye göre
  double? _accuracy; // iOS: derece hata; Android: 15/30/45; null: bilinmiyor
  int _compassSamples = 0;
  double _sinAcc = 0, _cosAcc = 1;
  bool _seeded = false;

  // Kalibrasyon durumu
  DateTime _calibStart = DateTime.now();
  DateTime? _goodSince;
  Timer? _calibTimer;
  bool _showSkip = false;

  // Konum + kıble
  StreamSubscription<Position>? _positionSub;
  double _declination = 0; // derece, doğuya + (gerçek = manyetik + bu)
  double? _qiblaTrue; // gerçek kuzeye göre kıble açısı
  bool _staleLocation = false;

  bool _aligned = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _beginCalibration();
  }

  @override
  void dispose() {
    _calibTimer?.cancel();
    _compassSub?.cancel();
    _positionSub?.cancel();
    _anim.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- kalibrasyon

  void _beginCalibration() {
    _calibStart = DateTime.now();
    _compassSamples = 0;
    _seeded = false;
    _goodSince = null;
    _showSkip = false;
    _anim.repeat();

    final stream = FlutterCompass.events;
    if (stream == null) {
      _hasCompass = false;
      // Pusula sensörü yok: kalibrasyonu atla.
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToLocating());
      return;
    }
    _hasCompass = true;
    _compassSub?.cancel();
    _compassSub = stream.listen(_onCompass, onError: (_) {});

    _calibTimer?.cancel();
    _calibTimer = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _evaluateCalibration(),
    );
  }

  void _onCompass(CompassEvent e) {
    _accuracy = e.accuracy;
    final raw = e.heading;
    if (raw == null || raw < 0) {
      // iOS: kalibrasyon yok / trueHeading yok.
      if (_phase == _Phase.ready && mounted) setState(() {});
      return;
    }
    _compassSamples++;

    final rad = raw * math.pi / 180;
    final s = math.sin(rad), c = math.cos(rad);
    if (!_seeded) {
      _sinAcc = s;
      _cosAcc = c;
      _seeded = true;
    } else {
      // Uyarlanır yumuşatma: büyük fark → hızlı yakala, küçük fark → stabil.
      final prev = math.atan2(_sinAcc, _cosAcc) * 180 / math.pi;
      final diff = _deltaDeg(prev, raw).abs();
      final k = diff > 25 ? 0.45 : (diff > 8 ? 0.22 : 0.12);
      _sinAcc = _sinAcc * (1 - k) + s * k;
      _cosAcc = _cosAcc * (1 - k) + c * k;
    }
    final smoothed = (math.atan2(_sinAcc, _cosAcc) * 180 / math.pi + 360) % 360;
    final changed = _smoothHeading == null ||
        _deltaDeg(_smoothHeading!, smoothed).abs() > 0.3;
    _smoothHeading = smoothed;

    if (_phase == _Phase.ready && changed && mounted) {
      setState(_updateAlignment);
    }
  }

  /// iOS'ta `accuracy` derece cinsinden hata payı (küçük = iyi);
  /// Android'de plugin 15 (yüksek) / 30 (orta) / 45 (düşük) sabitlerini verir.
  bool get _accuracyGood {
    final a = _accuracy;
    if (a == null) return false;
    if (_isIOS) return a > 0 && a <= 20;
    return a <= 30;
  }

  /// -1 bekleniyor · 0 zayıf · 1 orta · 2 iyi
  int get _calLevel {
    final a = _accuracy;
    if (a == null || (_isIOS && a <= 0)) return -1;
    if (_isIOS) {
      if (a <= 12) return 2;
      if (a <= 22) return 1;
      return 0;
    }
    if (a <= 15) return 2;
    if (a <= 30) return 1;
    return 0;
  }

  void _evaluateCalibration() {
    if (!mounted || _phase != _Phase.calibrating) return;
    final now = DateTime.now();

    if (_accuracyGood && _compassSamples > 12) {
      _goodSince ??= now;
      if (now.difference(_goodSince!) >= const Duration(milliseconds: 1400)) {
        _goToLocating();
        return;
      }
    } else {
      _goodSince = null;
    }

    final elapsed = now.difference(_calibStart);
    // Pusula 5 sn içinde hiç veri üretmediyse sensör yok say.
    if (_compassSamples == 0 && elapsed > const Duration(seconds: 5)) {
      _hasCompass = false;
      _goToLocating();
      return;
    }
    _showSkip = elapsed > const Duration(seconds: 8);
    setState(() {});
  }

  // --------------------------------------------------------------- konum + kıble

  Future<void> _goToLocating() async {
    if (_phase != _Phase.calibrating) return;
    _calibTimer?.cancel();
    _anim.stop();
    setState(() => _phase = _Phase.locating);

    // 1) İzin
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _fail('Konum servisi kapalı. Kıble için konumu açın.', perm: true);
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _fail('Konum izni kapalı. Ayarlar > Dilara üzerinden konuma izin verin.',
            perm: true);
        return;
      }
      if (perm == LocationPermission.denied) {
        _fail('Konum izni gerekli.', perm: true);
        return;
      }
    } catch (e) {
      _fail('Konum alınamadı: ${_clean('$e')}');
      return;
    }

    // 2) Taze, yüksek doğrulukta konum. Başarısızsa son bilinen (işaretli).
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      pos = null;
    }
    if (pos == null) {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        _fail('Konum alınamadı. Açık bir alanda tekrar deneyin.');
        return;
      }
      pos = last;
      _staleLocation = true;
    }

    await _applyPosition(pos, initial: true);
    if (!mounted) return;
    setState(() {
      _phase = _Phase.ready;
      _updateAlignment();
    });

    // 3) Konum akışı ile iyileştir.
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((p) => _applyPosition(p), onError: (_) {});
  }

  Future<void> _applyPosition(Position pos, {bool initial = false}) async {
    final qibla = _bearingToKaaba(pos.latitude, pos.longitude);
    var decl = _declination;
    if (!_isIOS) {
      decl = await _fetchDeclination(pos.latitude, pos.longitude, pos.altitude);
    }
    if (!mounted) return;

    final changed = _qiblaTrue == null ||
        _deltaDeg(_qiblaTrue!, qibla).abs() > 0.1 ||
        (decl - _declination).abs() > 0.1;
    if (!initial && !changed) return;

    setState(() {
      _qiblaTrue = qibla;
      _declination = decl;
      if (!initial) _staleLocation = false;
      if (_phase == _Phase.ready) _updateAlignment();
    });
  }

  Future<double> _fetchDeclination(double lat, double lng, double alt) async {
    try {
      final v = await _channel.invokeMethod<dynamic>(
        'getMagneticDeclination',
        {'lat': lat, 'lng': lng, 'alt': alt.isFinite ? alt : 0.0},
      );
      if (v is num && v.abs() < 90) return v.toDouble();
    } catch (_) {}
    return 0.0;
  }

  /// Gerçek kuzeye göre pusula yönü (Android: manyetik + sapma).
  double? get _trueHeading {
    final h = _smoothHeading;
    if (h == null) return null;
    return (h + _declination + 360) % 360;
  }

  void _updateAlignment() {
    final h = _trueHeading, q = _qiblaTrue;
    if (h == null || q == null) return;
    final aligned = _deltaDeg(h, q).abs() < 4;
    if (aligned != _aligned) {
      _aligned = aligned;
      if (aligned) HapticFeedback.mediumImpact();
    }
  }

  void _fail(String msg, {bool perm = false}) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _error = msg;
      _errorIsPermission = perm;
    });
  }

  void _restart() {
    _compassSub?.cancel();
    _positionSub?.cancel();
    _calibTimer?.cancel();
    setState(() {
      _phase = _Phase.calibrating;
      _error = null;
      _errorIsPermission = false;
      _smoothHeading = null;
      _accuracy = null;
      _qiblaTrue = null;
      _declination = 0;
      _staleLocation = false;
      _aligned = false;
    });
    _beginCalibration();
  }

  // -------------------------------------------------------------------- hesap

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

  // -------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.error:
        return _errorView();
      case _Phase.calibrating:
        return _calibrationView();
      case _Phase.locating:
        return const _Message(
          icon: Icons.my_location,
          text: 'Net konum alınıyor...',
          showSpinner: true,
        );
      case _Phase.ready:
        return _compassView();
    }
  }

  Widget _errorView() {
    return _Message(
      icon: Icons.location_off_outlined,
      text: _error ?? 'Bir hata oluştu.',
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _restart,
            child: const Text('Tekrar dene',
                style: TextStyle(color: V3Colors.primary)),
          ),
          if (_errorIsPermission)
            TextButton(
              onPressed: () => Geolocator.openAppSettings(),
              child: const Text('Ayarları Aç',
                  style: TextStyle(color: V3Colors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _calibrationView() {
    final level = _calLevel;
    const labels = ['Zayıf', 'Orta', 'İyi'];
    final label = level < 0 ? 'Sinyal bekleniyor' : labels[level];

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pusulayı kalibre edin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: V3Colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Telefonu elinize alıp havada birkaç kez ∞ (8) çizin. '
            'Kıble yönü ancak pusula düzeldikten sonra gösterilir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: V3Colors.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 180,
            height: 120,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, _) => CustomPaint(
                painter: _Figure8Painter(
                  _anim.value,
                  V3Colors.border,
                  V3Colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          _CalMeter(level: level),
          const SizedBox(height: 8),
          Text(
            'Doğruluk: $label',
            style: TextStyle(
              color: level == 2 ? Colors.green : V3Colors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          if (_showSkip)
            TextButton(
              onPressed: _phase == _Phase.calibrating ? _goToLocating : null,
              child: const Text('Kalibrasyonu atla',
                  style: TextStyle(color: V3Colors.primary)),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _compassView() {
    final qibla = _qiblaTrue!;
    final heading = _trueHeading ?? 0;
    final markerAngle = _deltaDeg(heading, qibla);
    final toGo = markerAngle.abs();
    final aligned = _trueHeading != null && toGo < 4;

    final lowAccuracy = _hasCompass && _trueHeading != null && _calLevel == 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_staleLocation)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Chip(
                icon: Icons.info_outline,
                text: 'Yaklaşık konum kullanılıyor',
              ),
            ),
          Text(
            _trueHeading == null
                ? 'Pusula sinyali bekleniyor'
                : aligned
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
            '${_trueHeading != null ? '   ·   Pusula: ${heading.toStringAsFixed(0)}°' : ''}'
            '${!_isIOS && _declination.abs() >= 0.5 ? '   ·   Sapma: ${_declination >= 0 ? '+' : ''}${_declination.toStringAsFixed(1)}°' : ''}',
            style: TextStyle(color: V3Colors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Kadran — gerçek kuzeye göre döner
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
              'Bu cihazda pusula sensörü yok. Kıble açısı kuzeye göre yukarıda '
              'gösteriliyor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: V3Colors.textMuted, fontSize: 12),
            )
          else if (lowAccuracy)
            Text(
              'Pusula doğruluğu düştü. Telefonu havada 8 çizerek yeniden '
              'kalibre edin.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB26A00), fontSize: 12),
            )
          else if (_trueHeading != null)
            Text(
              'Oku yukarı (ekranın üstüne) getirene kadar dönün.',
              textAlign: TextAlign.center,
              style: TextStyle(color: V3Colors.textMuted, fontSize: 12),
            ),
          if (_hasCompass) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _restart,
              child: const Text('Yeniden kalibre et',
                  style: TextStyle(color: V3Colors.primary, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kalibrasyon doğruluk ölçeri (3 kademe).
class _CalMeter extends StatelessWidget {
  final int level; // -1..2
  const _CalMeter({required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i < (level < 0 ? 0 : level + 1);
        return Container(
          width: 46,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? (level == 2 ? Colors.green : V3Colors.primary)
                : V3Colors.border,
          ),
        );
      }),
    );
  }
}

class _Figure8Painter extends CustomPainter {
  final double t; // 0..1
  final Color path;
  final Color dot;
  _Figure8Painter(this.t, this.path, this.dot);

  Offset _point(double u, Size size) {
    final a = size.width * 0.46;
    final b = size.height * 0.46;
    final s = math.sin(u), c = math.cos(u);
    final d = 1 + s * s;
    return Offset(
      size.width / 2 + a * c / d,
      size.height / 2 + b * s * c / d,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final track = Path();
    for (var i = 0; i <= 120; i++) {
      final o = _point(i / 120 * math.pi * 2, size);
      i == 0 ? track.moveTo(o.dx, o.dy) : track.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      track,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = path,
    );
    final head = _point(t * math.pi * 2, size);
    canvas.drawCircle(head, 7, Paint()..color = dot);
    canvas.drawCircle(
      head,
      12,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = dot.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _Figure8Painter old) => old.t != t;
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

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: V3Colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: V3Colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: V3Colors.textMuted),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(color: V3Colors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
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
