import 'package:flutter/material.dart';

import '../data/prayer.dart';
import '../theme.dart';

/// v2'deki (`lib/core/pages/notification_settings_page.dart`) ayrıntılı
/// namaz bildirimi ayarları ekranının v3 karşılığı: genel açma/kapama,
/// vakitten önce/sonra süre seçimi, vakit başına aç/kapa + sessiz bildirim.
class V3PrayerNotificationSettingsPage extends StatefulWidget {
  const V3PrayerNotificationSettingsPage({super.key});

  @override
  State<V3PrayerNotificationSettingsPage> createState() =>
      _V3PrayerNotificationSettingsPageState();
}

class _V3PrayerNotificationSettingsPageState
    extends State<V3PrayerNotificationSettingsPage> {
  static const _beforePresets = [15, 30, 45];
  static const _afterPresets = [15, 30, 45];

  bool _loading = true;
  bool _busy = false;
  bool _masterEnabled = false;
  int _offsetMinutes = 45;
  bool _offsetIsBefore = true;
  Map<String, V3PrayerNotifSetting> _settings = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await V3PrayerRepository.notificationsEnabled();
    final offsetMinutes = await V3PrayerRepository.offsetMinutes();
    final offsetIsBefore = await V3PrayerRepository.offsetIsBefore();
    final settings = await V3PrayerRepository.perPrayerSettings();
    if (!mounted) return;
    setState(() {
      _masterEnabled = enabled;
      _offsetMinutes = offsetMinutes;
      _offsetIsBefore = offsetIsBefore;
      _settings = settings;
      _loading = false;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _toggleMaster(bool value) async {
    setState(() => _busy = true);
    try {
      await V3PrayerRepository.setNotificationsEnabled(value);
      if (mounted) {
        setState(() => _masterEnabled = value);
        _showSnack(value ? 'Bildirimler açıldı' : 'Bildirimler kapatıldı');
      }
    } catch (e) {
      _showSnack('$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setOffset(int minutes, bool isBefore) async {
    setState(() {
      _offsetMinutes = minutes;
      _offsetIsBefore = isBefore;
    });
    await V3PrayerRepository.setOffset(minutes, isBefore);
    if (_masterEnabled) await V3PrayerRepository.rescheduleAll();
  }

  Future<void> _setPrayerEnabled(String key, bool value) async {
    setState(() => _settings[key]!.enabled = value);
    await V3PrayerRepository.savePrayerSetting(key, _settings[key]!);
    if (_masterEnabled) await V3PrayerRepository.rescheduleAll();
  }

  Future<void> _setPrayerSilent(String key, bool value) async {
    setState(() => _settings[key]!.isSilent = value);
    await V3PrayerRepository.savePrayerSetting(key, _settings[key]!);
    if (_masterEnabled) await V3PrayerRepository.rescheduleAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Namaz Bildirimi Ayarları')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: V3Colors.primary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: V3Colors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    activeThumbColor: V3Colors.primary,
                    title: const Text('Namaz vakti bildirimleri'),
                    subtitle: Text('Tüm vakit bildirimlerini aç/kapat',
                        style:
                            TextStyle(fontSize: 12, color: V3Colors.textMuted)),
                    value: _masterEnabled,
                    onChanged: _busy ? null : _toggleMaster,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: _masterEnabled ? 1 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_masterEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bildirim Zamanı',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'Namaz vaktinden $_offsetMinutes dk '
                          '${_offsetIsBefore ? "önce" : "sonra"} bildirim gönderilir.',
                          style: TextStyle(
                              color: V3Colors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _beforePresets
                              .map((m) => Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: _PresetChip(
                                        label: '$m dk önce',
                                        selected: _offsetIsBefore &&
                                            _offsetMinutes == m,
                                        onTap: () => _setOffset(m, true),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _afterPresets
                              .map((m) => Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8),
                                      child: _PresetChip(
                                        label: '$m dk sonra',
                                        selected: !_offsetIsBefore &&
                                            _offsetMinutes == m,
                                        onTap: () => _setOffset(m, false),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        const Text('Namaz Vakitleri',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 8),
                        ...V3PrayerTimes.order.map((key) {
                          final setting = _settings[key];
                          if (setting == null) return const SizedBox.shrink();
                          final label = V3PrayerTimes.trNames[key] ?? key;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: V3Colors.surface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  activeThumbColor: V3Colors.primary,
                                  title: Text(label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  value: setting.enabled,
                                  onChanged: (v) => _setPrayerEnabled(key, v),
                                ),
                                if (setting.enabled)
                                  SwitchListTile(
                                    dense: true,
                                    activeThumbColor: V3Colors.textMuted,
                                    title: const Text('Sessiz bildirim',
                                        style: TextStyle(fontSize: 13)),
                                    subtitle: Text(
                                        'Sadece bildirim gelir, ses çalmaz',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: V3Colors.textMuted)),
                                    value: setting.isSilent,
                                    onChanged: (v) =>
                                        _setPrayerSilent(key, v),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? V3Colors.primary : V3Colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? V3Colors.primary : V3Colors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : V3Colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
