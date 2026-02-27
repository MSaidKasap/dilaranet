import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utill/notifications.dart';

// ─── Ses seçenekleri ───────────────────────────────────────────────────────────
class NotificationSound {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String? assetPath;

  const NotificationSound({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.assetPath,
  });
}

const List<NotificationSound> kSoundOptions = [
  NotificationSound(
    id: 'default',
    label: 'Varsayılan',
    subtitle: 'Sistem bildirimi',
    icon: Icons.notifications_rounded,
  ),
];

// ─── Dakika presetleri ─────────────────────────────────────────────────────────
class TimePreset {
  final int minutes;
  final String label;
  final bool isBefore;

  const TimePreset(this.minutes, this.label, {required this.isBefore});
}

const List<TimePreset> kBeforePresets = [
  TimePreset(15, '15 dk ', isBefore: true),
  TimePreset(30, '30 dk ', isBefore: true),
  TimePreset(45, '45 dk ', isBefore: true),
];

const List<TimePreset> kAfterPresets = [
  TimePreset(15, '15 dk sonra', isBefore: false),
  TimePreset(30, '30 dk sonra', isBefore: false),
  TimePreset(45, '45 dk sonra', isBefore: false),
];

// ─── Namaz bilgileri ───────────────────────────────────────────────────────────
class PrayerInfo {
  final String key;
  final String label;
  final String arabicName;
  final IconData icon;
  final Color color;

  const PrayerInfo({
    required this.key,
    required this.label,
    required this.arabicName,
    required this.icon,
    required this.color,
  });
}

const List<PrayerInfo> kPrayers = [
  PrayerInfo(
    key: 'Fajr',
    label: 'İmsak',
    arabicName: 'الفجر',
    icon: Icons.nights_stay_rounded,
    color: Color(0xFF6C63FF),
  ),
  PrayerInfo(
    key: 'Sunrise',
    label: 'Güneş',
    arabicName: 'الشروق',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFFF9F43),
  ),
  PrayerInfo(
    key: 'Dhuhr',
    label: 'Öğle',
    arabicName: 'الظهر',
    icon: Icons.light_mode_rounded,
    color: Color(0xFF54A0FF),
  ),
  PrayerInfo(
    key: 'Asr',
    label: 'İkindi',
    arabicName: 'العصر',
    icon: Icons.wb_cloudy_rounded,
    color: Color(0xFF5F27CD),
  ),
  PrayerInfo(
    key: 'Maghrib',
    label: 'Akşam',
    arabicName: 'المغرب',
    icon: Icons.wb_twilight_rounded,
    color: Color(0xFFFF6B6B),
  ),
  PrayerInfo(
    key: 'Isha',
    label: 'Yatsı',
    arabicName: 'العشاء',
    icon: Icons.dark_mode_rounded,
    color: Color(0xFF2C3E50),
  ),
];

// ─── Her vakit için özel ayar modeli ───────────────────────────────────────────
class PrayerSetting {
  bool enabled;
  String soundId;
  bool isSilent;

  PrayerSetting({
    required this.enabled,
    required this.soundId,
    required this.isSilent,
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'soundId': soundId,
    'isSilent': isSilent,
  };

  factory PrayerSetting.fromJson(Map<String, dynamic> json) => PrayerSetting(
    enabled: json['enabled'] ?? false,
    soundId: json['soundId'] ?? 'default',
    isSilent: json['isSilent'] ?? false,
  );
}

// ─── Ana Sayfa ─────────────────────────────────────────────────────────────────
class NotificationSettingsPage extends StatefulWidget {
  /// Bugünün (ve yarının) namaz vakitleri.
  /// {"Fajr": "05:12", "Sunrise": "06:45", ...} formatında.
  /// Dışarıdan geçirilmezse bildirim zamanlaması yapılamaz.
  final Map<String, String>? todayPrayerTimes;
  final Map<String, String>? tomorrowPrayerTimes;

  const NotificationSettingsPage({
    super.key,
    this.todayPrayerTimes,
    this.tomorrowPrayerTimes,
  });

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage>
    with TickerProviderStateMixin {
  final _service = NotificationService();

  bool masterEnabled = false;
  int offsetMinutes = 30;
  bool offsetIsBefore = true;
  String globalSoundId = 'default';
  bool isVisible = false;
  late Map<String, PrayerSetting> prayerSettings;

  bool loading = true;
  bool permissionAllowed = false;

  late AnimationController _masterSwitchController;
  late Animation<double> _masterSwitchAnim;

  @override
  void initState() {
    super.initState();
    _masterSwitchController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _masterSwitchAnim = CurvedAnimation(
      parent: _masterSwitchController,
      curve: Curves.easeOutCubic,
    );
    _initPrayerSettings();
    _load();
  }

  void _initPrayerSettings() {
    prayerSettings = {
      for (var p in kPrayers)
        p.key: PrayerSetting(
          enabled: p.key != 'Sunrise',
          soundId: 'default',
          isSilent: false,
        ),
    };
  }

  @override
  void dispose() {
    _masterSwitchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    masterEnabled = sp.getBool('notify_enabled') ?? false;
    offsetMinutes = sp.getInt('notify_offset_minutes') ?? 30;
    offsetIsBefore = sp.getBool('notify_offset_is_before') ?? true;
    globalSoundId = sp.getString('notify_sound_id') ?? 'default';

    // ✅ DÜZELTME: JSON string olarak kaydet/oku (dart:convert kullan)
    for (final p in kPrayers) {
      final jsonString = sp.getString('prayer_setting_${p.key}');
      if (jsonString != null) {
        try {
          final Map<String, dynamic> json = jsonDecode(jsonString);
          prayerSettings[p.key] = PrayerSetting.fromJson(json);
        } catch (e) {
          print("⚠️ ${p.key} ayarı yüklenemedi: $e");
          // Hata durumunda varsayılanı kullan
        }
      }
    }

    permissionAllowed = await _service.isNotificationAllowed();

    if (masterEnabled) _masterSwitchController.forward();

    if (mounted) setState(() => loading = false);
  }

  Future<void> _persist() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('notify_enabled', masterEnabled);
    await sp.setInt('notify_offset_minutes', offsetMinutes);
    await sp.setBool('notify_offset_is_before', offsetIsBefore);
    await sp.setString('notify_sound_id', globalSoundId);

    // ✅ DÜZELTME: jsonEncode ile doğru JSON string'e çevir
    for (final entry in prayerSettings.entries) {
      await sp.setString(
        'prayer_setting_${entry.key}',
        jsonEncode(entry.value.toJson()),
      );
    }
  }

  /// Ayarlar değiştiğinde hem persist et hem bildirimleri yeniden zamanla.
  Future<void> _persistAndReschedule() async {
    await _persist();
    if (masterEnabled) {
      await _rescheduleAll();
    }
  }

  /// Tüm mevcut bildirimleri iptal edip yeniden zamanlar.
  Future<void> _rescheduleAll() async {
    await _service.cancelAllNotifications();

    if (widget.todayPrayerTimes == null) {
      print("⚠️ todayPrayerTimes null, zamanlama yapılamıyor");
      return;
    }

    final now = DateTime.now();

    // Bugün
    await _service.scheduleForDay(
      day: now,
      times: widget.todayPrayerTimes!,
      locationText: '',
      offsetMinutes: offsetMinutes,
      offsetIsBefore: offsetIsBefore,
      prayerEnabled: {
        for (final e in prayerSettings.entries) e.key: e.value.enabled,
      },
      prayerSoundId: {
        for (final e in prayerSettings.entries) e.key: e.value.soundId,
      },
      prayerIsSilent: {
        for (final e in prayerSettings.entries) e.key: e.value.isSilent,
      },
      prayerLabels: {for (final p in kPrayers) p.key: p.label},
      prayerArabicNames: {for (final p in kPrayers) p.key: p.arabicName},
    );

    // Yarın (varsa)
    if (widget.tomorrowPrayerTimes != null) {
      await _service.scheduleForDay(
        day: now.add(const Duration(days: 1)),
        times: widget.tomorrowPrayerTimes!,
        locationText: '',
        offsetMinutes: offsetMinutes,
        offsetIsBefore: offsetIsBefore,
        prayerEnabled: {
          for (final e in prayerSettings.entries) e.key: e.value.enabled,
        },
        prayerSoundId: {
          for (final e in prayerSettings.entries) e.key: e.value.soundId,
        },
        prayerIsSilent: {
          for (final e in prayerSettings.entries) e.key: e.value.isSilent,
        },
        prayerLabels: {for (final p in kPrayers) p.key: p.label},
        prayerArabicNames: {for (final p in kPrayers) p.key: p.arabicName},
      );
    }

    print("✅ Tüm bildirimler yeniden zamanlandı");
  }

  void _setPreset(TimePreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      offsetMinutes = preset.minutes;
      offsetIsBefore = preset.isBefore;
    });
    _persistAndReschedule();
  }

  bool _isPresetSelected(TimePreset preset) {
    return offsetMinutes == preset.minutes && offsetIsBefore == preset.isBefore;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F14) : const Color(0xFFF0F2F8);
    final cardBg = isDark ? const Color(0xFF1A1A24) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final textSecondary = isDark ? Colors.white54 : Colors.black45;
    final accent = const Color(0xFF7C6FE0);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Bildirim Ayarları',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withOpacity(0.15), bg],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Ana Switch
                _MasterToggleCard(
                  enabled: masterEnabled,
                  permissionAllowed: permissionAllowed,
                  accent: accent,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  onToggle: (v) async {
                    HapticFeedback.mediumImpact();
                    if (v) {
                      final ok = await _service.requestNotificationPermission();
                      setState(() {
                        permissionAllowed = ok;
                        masterEnabled = ok;
                      });
                      if (ok) {
                        _masterSwitchController.forward();
                        await _rescheduleAll(); // ✅ Aç → hemen zamanla
                        _showSnack('Bildirimler açıldı ✓', Colors.green);
                      } else {
                        _showSnack('Bildirim izni gerekli', Colors.orange);
                      }
                    } else {
                      setState(() => masterEnabled = false);
                      _masterSwitchController.reverse();
                      await _service.cancelAllNotifications();
                      _showSnack('Bildirimler kapatıldı', Colors.grey);
                    }
                    await _persist();
                  },
                ),

                const SizedBox(height: 20),

                // Zaman Seçici
                AnimatedBuilder(
                  animation: _masterSwitchAnim,
                  builder: (context, child) => AnimatedOpacity(
                    opacity: masterEnabled ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: !masterEnabled,
                      child: child,
                    ),
                  ),
                  child: _SectionCard(
                    cardBg: cardBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.schedule_rounded,
                          label: 'Bildirim Zamanı',
                          accent: accent,
                          textPrimary: textPrimary,
                        ),

                        const SizedBox(height: 8),
                        Row(
                          children: kBeforePresets.map((p) {
                            final selected = _isPresetSelected(p);
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _PresetChip(
                                  label: p.label,
                                  selected: selected,
                                  accent: accent,
                                  isDark: isDark,
                                  onTap: () => _setPreset(p),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: accent.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: accent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Namaz vaktinden $offsetMinutes dk '
                                '${offsetIsBefore ? "önce" : "sonra"} bildirim',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Namaz Vakitleri
                AnimatedOpacity(
                  opacity: masterEnabled ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !masterEnabled,
                    child: _SectionCard(
                      cardBg: cardBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            icon: Icons.mosque_rounded,
                            label: 'Namaz Vakitleri',
                            accent: accent,
                            textPrimary: textPrimary,
                          ),
                          const SizedBox(height: 14),
                          ...kPrayers.map((prayer) {
                            final setting = prayerSettings[prayer.key]!;
                            return _PrayerSettingTile(
                              prayer: prayer,
                              setting: setting,
                              soundOptions: kSoundOptions,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              isDark: isDark,
                              onEnabledChanged: (v) {
                                setState(() {
                                  prayerSettings[prayer.key]!.enabled = v;
                                });
                                _persistAndReschedule(); // ✅ yeniden zamanla
                              },
                              onSoundChanged: (soundId) {
                                setState(() {
                                  prayerSettings[prayer.key]!.soundId = soundId;
                                  if (soundId != 'default') {
                                    prayerSettings[prayer.key]!.isSilent =
                                        false;
                                  }
                                });
                                _persistAndReschedule(); // ✅ yeniden zamanla
                              },
                              onSilentChanged: (isSilent) {
                                setState(() {
                                  prayerSettings[prayer.key]!.isSilent =
                                      isSilent;
                                  if (isSilent) {
                                    prayerSettings[prayer.key]!.soundId =
                                        'default';
                                  }
                                });
                                _persistAndReschedule(); // ✅ yeniden zamanla
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Test Butonu
                AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !isVisible,
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: masterEnabled
                            ? () async {
                                HapticFeedback.mediumImpact();

                                // Aktif (enabled) vakitlerden birini seç
                                final enabledPrayers = kPrayers
                                    .where(
                                      (p) => prayerSettings[p.key]!.enabled,
                                    )
                                    .toList();

                                final testPrayer = enabledPrayers.isNotEmpty
                                    ? enabledPrayers[Random().nextInt(
                                        enabledPrayers.length,
                                      )]
                                    : kPrayers.first;

                                final setting = prayerSettings[testPrayer.key]!;

                                // Sessiz modda 'default', değilse vaktin seçili sesi
                                final soundId = setting.isSilent
                                    ? 'default'
                                    : setting.soundId;

                                await _service.showImmediateNotification(
                                  soundId: soundId,
                                  remainingMinutes: offsetMinutes,
                                );

                                final soundLabel = kSoundOptions
                                    .firstWhere(
                                      (s) => s.id == soundId,
                                      orElse: () => kSoundOptions.first,
                                    )
                                    .subtitle;

                                _showSnack(
                                  '🔔 ${testPrayer.label} · $offsetMinutes dk ${offsetIsBefore ? "önce" : "sonra"} · $soundLabel',
                                  accent,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: const Text(
                          'Test Bildirimi Gönder',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Yardımcı Widgetlar ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color cardBg;

  const _SectionCard({required this.child, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color textPrimary;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.accent,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}

class _MasterToggleCard extends StatelessWidget {
  final bool enabled;
  final bool permissionAllowed;
  final Color accent;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Function(bool) onToggle;

  const _MasterToggleCard({
    required this.enabled,
    required this.permissionAllowed,
    required this.accent,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Ana kart ──────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: enabled
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [accent, accent.withBlue(255)],
                        )
                      : null,
                  color: enabled ? null : cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: enabled
                          ? accent.withOpacity(0.35)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: enabled ? 20 : 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: enabled
                            ? Colors.white.withOpacity(0.2)
                            : accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        enabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        color: enabled ? Colors.white : accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Namaz Bildirimleri',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: enabled ? Colors.white : textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: enabled
                                      ? Colors.greenAccent
                                      : (permissionAllowed
                                            ? Colors.orange
                                            : Colors.red),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                enabled
                                    ? 'Aktif'
                                    : (permissionAllowed
                                          ? 'Kapalı'
                                          : 'İzin gerekli'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: enabled
                                      ? Colors.white70
                                      : textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bu uygulama test sürümündedir.',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: enabled
                                  ? Colors.white54
                                  : textSecondary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: enabled,
                      onChanged: onToggle,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withOpacity(0.4),
                      inactiveThumbColor: accent,
                      inactiveTrackColor: accent.withOpacity(0.2),
                    ),
                  ],
                ),
              ),

              // ── BETA rozeti (sağ üst köşe, çapraz) ───────────
              Positioned(
                top: 10,
                right: -22,
                child: Transform.rotate(
                  angle: 0.7854, // 45 derece
                  child: Container(
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.red,
                    alignment: Alignment.center,
                    child: const Text(
                      'BETA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Uyarı notu ────────────────────────────────────────
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bildirim servisi test sürümündedir. Bazı bildirimlerde gecikmeler veya hatalar yaşanabilir.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : (isDark
                    ? Colors.white.withOpacity(0.07)
                    : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }
}

class _PrayerSettingTile extends StatefulWidget {
  final PrayerInfo prayer;
  final PrayerSetting setting;
  final List<NotificationSound> soundOptions;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final Function(bool) onEnabledChanged;
  final Function(String) onSoundChanged;
  final Function(bool) onSilentChanged;

  const _PrayerSettingTile({
    required this.prayer,
    required this.setting,
    required this.soundOptions,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onEnabledChanged,
    required this.onSoundChanged,
    required this.onSilentChanged,
  });

  @override
  State<_PrayerSettingTile> createState() => _PrayerSettingTileState();
}

class _PrayerSettingTileState extends State<_PrayerSettingTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final prayer = widget.prayer;
    final setting = widget.setting;
    final isEnabled = setting.enabled;
    final isSilent = setting.isSilent;
    final selectedSound = widget.soundOptions.firstWhere(
      (s) => s.id == setting.soundId,
      orElse: () => widget.soundOptions.first,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isEnabled
            ? prayer.color.withOpacity(0.05)
            : (widget.isDark
                  ? Colors.white.withOpacity(0.02)
                  : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? prayer.color.withOpacity(0.2) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: prayer.color.withOpacity(isEnabled ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        prayer.icon,
                        size: 20,
                        color: prayer.color.withOpacity(isEnabled ? 1.0 : 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prayer.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isEnabled
                                  ? widget.textPrimary
                                  : widget.textPrimary.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isEnabled && !_expanded) ...[
                      if (isSilent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_off_rounded,
                                size: 14,
                                color: widget.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Sessiz',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: prayer.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.volume_up_rounded,
                                size: 14,
                                color: prayer.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                selectedSound.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: prayer.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                    ],
                    Switch(
                      value: isEnabled,
                      onChanged: widget.onEnabledChanged,
                      activeColor: prayer.color,
                      activeTrackColor: prayer.color.withOpacity(0.25),
                      inactiveThumbColor: widget.textSecondary.withOpacity(0.4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded && isEnabled)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.volume_up_rounded,
                        size: 16,
                        color: widget.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bildirim Sesi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (isSilent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Sessiz modda ses seçilemez',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  IgnorePointer(
                    ignoring: isSilent,
                    child: Opacity(
                      opacity: isSilent ? 0.5 : 1.0,
                      child: SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.soundOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final sound = widget.soundOptions[index];
                            final isSelected = setting.soundId == sound.id;
                            return GestureDetector(
                              onTap: isSilent
                                  ? null
                                  : () => widget.onSoundChanged(sound.id),
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? prayer.color.withOpacity(0.2)
                                      : (widget.isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.03)),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? prayer.color
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      sound.icon,
                                      color: isSelected
                                          ? prayer.color
                                          : widget.textSecondary,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sound.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? prayer.color
                                            : widget.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      sound.subtitle,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: widget.textSecondary.withOpacity(
                                          0.7,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSilent
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          size: 18,
                          color: isSilent ? Colors.grey : prayer.color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sessiz Bildirim',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: widget.textPrimary,
                                ),
                              ),
                              Text(
                                isSilent
                                    ? 'Sadece bildirim gelir, ses çalmaz'
                                    : 'Sesli bildirim almak için kapatın',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isSilent,
                          onChanged: widget.onSilentChanged,
                          activeColor: Colors.grey,
                          inactiveThumbColor: prayer.color,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
