import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/prayer.dart';
import '../theme.dart';
import 'prayer_notification_settings_page.dart';

class V3PrayerPage extends StatefulWidget {
  const V3PrayerPage({super.key});

  @override
  State<V3PrayerPage> createState() => _V3PrayerPageState();
}

class _V3PrayerPageState extends State<V3PrayerPage> {
  V3PrayerTimes? _data;
  String? _error;
  bool _loading = true;
  bool _notif = false;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  String _nextName = '';

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Arka planda konum değişikliği tespit edilip taze veri çekilirse yeniden
    // yükle (v2'deki "şehir değişti" davranışı).
    V3PrayerRepository.revision.addListener(_onRevision);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    V3PrayerRepository.revision.removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() {
    if (mounted) _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await V3PrayerRepository.load(forceRefresh: force);
      final enabled = await V3PrayerRepository.notificationsEnabled();
      if (enabled) await V3PrayerRepository.rescheduleAll(today: data);
      if (!mounted) return;
      setState(() {
        _data = data;
        _notif = enabled;
        _loading = false;
      });
      _tick();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _tick() {
    final data = _data;
    if (data == null) return;
    final next = data.nextPrayer;
    if (next == null) {
      setState(() {
        _nextName = 'Yatsı sonrası';
        _remaining = Duration.zero;
      });
      return;
    }
    final label = V3PrayerTimes.trNames[next.key] ?? next.key;
    setState(() {
      _nextName = next.tomorrow ? '$label (yarın)' : label;
      _remaining = next.at.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  Future<void> _toggleNotif(bool value) async {
    setState(() => _notif = value);
    try {
      await V3PrayerRepository.setNotificationsEnabled(value, today: _data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value
              ? 'Namaz vakti bildirimleri açıldı'
              : 'Bildirimler kapatıldı'),
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _notif = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: V3Colors.primary));
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: () => _load(force: true));
    }
    final data = _data!;
    return RefreshIndicator(
      color: V3Colors.primary,
      onRefresh: () => _load(force: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, size: 18, color: V3Colors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(data.locationName,
                    style: TextStyle(color: V3Colors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _countdownCard(),
          const SizedBox(height: 16),
          ...V3PrayerTimes.order.map(_prayerRow),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeThumbColor: V3Colors.primary,
            title: const Text('Namaz vakti bildirimleri'),
            subtitle: Text('Her vakitten önce hatırlat',
                style: TextStyle(fontSize: 12, color: V3Colors.textMuted)),
            value: _notif,
            onChanged: _toggleNotif,
            secondary: IconButton(
              icon: Icon(Icons.tune_rounded, color: V3Colors.textMuted),
              tooltip: 'Vakit başına ayarlar',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const V3PrayerNotificationSettingsPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdownCard() {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;
    final text = _remaining == Duration.zero
        ? '—'
        : '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: V3Colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('Sıradaki: $_nextName',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _prayerRow(String key) {
    final data = _data!;
    final next = data.nextPrayer;
    final isNext = next != null && !next.tomorrow && next.key == key;
    final name = V3PrayerTimes.trNames[key] ?? key;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isNext ? V3Colors.primary.withValues(alpha: 0.08) : V3Colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: isNext ? Border.all(color: V3Colors.primary) : null,
      ),
      child: Row(
        children: [
          Icon(_iconFor(key),
              size: 20, color: isNext ? V3Colors.primary : V3Colors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                    color: isNext ? V3Colors.primary : V3Colors.textPrimary)),
          ),
          Text(data.times[key] ?? '--:--',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: isNext ? V3Colors.primary : V3Colors.textPrimary)),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'Fajr':
        return Icons.nightlight_outlined;
      case 'Sunrise':
        return Icons.wb_twilight;
      case 'Dhuhr':
        return Icons.wb_sunny_outlined;
      case 'Asr':
        return Icons.wb_cloudy_outlined;
      case 'Maghrib':
        return Icons.brightness_4_outlined;
      default:
        return Icons.nights_stay_outlined;
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isPermission = message.toLowerCase().contains('izin') ||
        message.toLowerCase().contains('konum');
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Icon(Icons.location_off_outlined, size: 48, color: V3Colors.textMuted),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: V3Colors.textMuted)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: onRetry,
              child: const Text('Tekrar dene',
                  style: TextStyle(color: V3Colors.primary)),
            ),
            if (isPermission)
              TextButton(
                onPressed: () => Geolocator.openAppSettings(),
                child: const Text('Ayarları Aç',
                    style: TextStyle(color: V3Colors.primary)),
              ),
          ],
        ),
      ],
    );
  }
}
