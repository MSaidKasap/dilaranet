import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../utill/notifications.dart';
import '../../utill/database_helper.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({Key? key}) : super(key: key);

  @override
  _PrayerTimesPageState createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  Map<String, dynamic>? prayerTimes;
  bool isLoading = true;
  String currentLocation = 'Konum alınıyor...';
  String currentDate = '';
  Position? currentPosition;
  Timer? _timer;
  String nextPrayerName = '';
  String timeToNextPrayer = '';
  Database? _database;

  bool isDataFromCache = false;
  bool locationPermissionGranted = false;

  bool _initialized = false;
  bool _isFetching = false; // aynı anda 2 fetch olmasın
  String currentTime = '';

  final NotificationService _notificationService = NotificationService();

  final Map<String, String> prayerNames = {
    'Fajr': 'İmsak',
    'Sunrise': 'Güneş',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };

  final Map<String, IconData> prayerIcons = {
    'İmsak': Icons.nights_stay,
    'Güneş': Icons.wb_sunny,
    'Öğle': Icons.wb_sunny,
    'İkindi': Icons.cloud,
    'Akşam': Icons.nights_stay,
    'Yatsı': Icons.nights_stay_outlined,
  };

  final Map<String, Color> prayerColors = {
    'Fajr': Colors.indigo,
    'Sunrise': Colors.orange,
    'Dhuhr': Colors.amber,
    'Asr': Colors.deepOrange,
    'Maghrib': Colors.red,
    'Isha': Colors.purple,
  };

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  @override
  void initState() {
    super.initState();
    _updateCurrentDate();
    _startTimer();
    _initOnce();
  }

  Future<void> _initOnce() async {
    if (_initialized) return;
    _initialized = true;

    await _checkLocationPermissionStatus();
    await _initializeDatabase();
    await _loadPrayerTimesFromDB();
  }

  Future<void> _checkLocationPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      locationPermissionGranted =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // ❗ DB'yi burada kapatma -> sayfalar arası gidip gelince “db hazır değil” / race condition yapabiliyor
    // _database?.close();
    super.dispose();
  }

  Future<void> _initializeDatabase() async {
    try {
      final path = join(await getDatabasesPath(), 'prayer_times.db');
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE locations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              location_name TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE prayer_times (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              location_id INTEGER NOT NULL,
              date TEXT NOT NULL,
              fajr TEXT NOT NULL,
              sunrise TEXT NOT NULL,
              dhuhr TEXT NOT NULL,
              asr TEXT NOT NULL,
              maghrib TEXT NOT NULL,
              isha TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY (location_id) REFERENCES locations (id),
              UNIQUE(location_id, date)
            )
          ''');
        },
      );
      print('✅ Veritabanı başlatıldı');
    } catch (e) {
      print('❌ Veritabanı hatası: $e');
    }
  }

  // Veritabanından namaz vakitlerini yükle
  Future<void> _loadPrayerTimesFromDB() async {
    try {
      final db = _database;
      if (db == null) {
        print('⚠️ _database henüz hazır değil, tekrar deneniyor');
        await _initializeDatabase();
        final db2 = _database;
        if (db2 == null) {
          _getCurrentLocation();
          return;
        }
      }

      final dbSafe = _database!;
      final locations = await dbSafe.query(
        'locations',
        orderBy: 'updated_at DESC',
        limit: 1,
      );

      if (locations.isEmpty) {
        print('📍 Konum bilgisi bulunamadı, yeni konum alınıyor');
        _getCurrentLocation();
        return;
      }

      final location = locations.first;

      final locationId = _toInt(location['id']);
      final lat = _toDouble(location['latitude']);
      final lon = _toDouble(location['longitude']);
      final locName = (location['location_name'] as String?)?.trim();

      if (locationId == null || lat == null || lon == null) {
        print(
          '⚠️ DB konum kaydı eksik/bozuk: id=$locationId lat=$lat lon=$lon',
        );
        _getCurrentLocation();
        return;
      }

      if (!mounted) return;
      setState(() {
        currentLocation = locName ?? 'Bilinmeyen Konum';
        currentPosition = Position(
          latitude: lat,
          longitude: lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      });

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final prayerTimesResult = await dbSafe.query(
        'prayer_times',
        where: 'location_id = ? AND date = ?',
        whereArgs: [locationId, today],
        limit: 1,
      );

      // ✅ Cache varsa UI’yı hemen aç
      // ✅ Cache varsa UI'yı hemen aç
      if (prayerTimesResult.isNotEmpty) {
        final times = prayerTimesResult.first;

        final newPrayerTimes = {
          'Fajr': (times['fajr'] as String?) ?? '',
          'Sunrise': (times['sunrise'] as String?) ?? '',
          'Dhuhr': (times['dhuhr'] as String?) ?? '',
          'Asr': (times['asr'] as String?) ?? '',
          'Maghrib': (times['maghrib'] as String?) ?? '',
          'Isha': (times['isha'] as String?) ?? '',
        };

        if (!mounted) return;
        setState(() {
          prayerTimes = newPrayerTimes;
          isLoading = false;
          isDataFromCache = true;
        });

        _calculateNextPrayer();

        // ✅ BURASI EKLENDİ
        await _savePrayerTimesToAppGroup(
          newPrayerTimes.map((k, v) => MapEntry(k, v.toString())),
        );

        _updatePrayerTimesInBackground();
        return;
      }

      // Bugünün verisi yoksa API
      final pos = currentPosition;
      if (pos == null) {
        _getCurrentLocation();
        return;
      }

      print('📅 Bugünün verisi bulunamadı, API\'den çekiliyor');
      await _fetchPrayerTimesFor30Days(pos.latitude, pos.longitude, locationId);
    } catch (e, st) {
      print('❌ Veritabanından veri yükleme hatası: $e');
      print(st);
      _getCurrentLocation();
    }
  }

  // Arka planda verileri güncelle (UI’yı kilitlemesin)
  Future<void> _updatePrayerTimesInBackground() async {
    final db = _database;
    if (db == null) return;

    try {
      final locations = await db.query(
        'locations',
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      if (locations.isEmpty) return;

      final location = locations.first;
      final updatedAtStr = location['updated_at'] as String?;
      if (updatedAtStr == null) return;

      final lastUpdate = DateTime.tryParse(updatedAtStr);
      if (lastUpdate == null) return;

      final daysDifference = DateTime.now().difference(lastUpdate).inDays;
      if (daysDifference < 1) return;

      final lat = _toDouble(location['latitude']);
      final lon = _toDouble(location['longitude']);
      final locationId = _toInt(location['id']);
      if (lat == null || lon == null || locationId == null) return;

      print('🔄 Arka plan güncelleme başlıyor ($daysDifference gün geçti)');

      await _fetchPrayerTimesFor30Days(
        lat,
        lon,
        locationId,
        background: true, // ✅ loader açma
      );
    } catch (e) {
      print('❌ Arka plan güncelleme hatası: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _updateCurrentDate();
      _updateCurrentTime();
      _calculateNextPrayer();
    });
  }

  void _updateCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd MMMM yyyy EEEE', 'en_US');
    if (!mounted) return;
    setState(() {
      currentDate = formatter.format(now);
    });
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    if (!mounted) return;
    setState(() {
      currentTime = DateFormat('HH:mm').format(now);
    });
  }

  void _calculateNextPrayer() {
    if (prayerTimes == null) return;

    final now = DateTime.now();
    final prayerTimesList = [
      {'name': 'İmsak', 'time': prayerTimes!['Fajr']},
      {'name': 'Güneş', 'time': prayerTimes!['Sunrise']},
      {'name': 'Öğle', 'time': prayerTimes!['Dhuhr']},
      {'name': 'İkindi', 'time': prayerTimes!['Asr']},
      {'name': 'Akşam', 'time': prayerTimes!['Maghrib']},
      {'name': 'Yatsı', 'time': prayerTimes!['Isha']},
    ];

    DateTime? nextPrayerTime;
    String nextName = '';

    for (var prayer in prayerTimesList) {
      final timeStr = (prayer['time'] ?? '').toString();
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final prayerDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      if (prayerDateTime.isAfter(now)) {
        nextPrayerTime = prayerDateTime;
        nextName = prayer['name'] as String;
        break;
      }
    }

    if (nextPrayerTime == null) {
      _getNextDayFirstPrayer(now);
      return;
    }

    final diff = nextPrayerTime.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (!mounted) return;
    setState(() {
      nextPrayerName = nextName;
      timeToNextPrayer =
          '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _getNextDayFirstPrayer(DateTime now) async {
    try {
      final db = _database;
      if (db == null) return;

      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);

      final locations = await db.query(
        'locations',
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      if (locations.isEmpty) return;

      final locationId = _toInt(locations.first['id']);
      if (locationId == null) return;

      final tomorrowTimes = await db.query(
        'prayer_times',
        where: 'location_id = ? AND date = ?',
        whereArgs: [locationId, tomorrowStr],
        limit: 1,
      );
      if (tomorrowTimes.isEmpty) return;

      final fajrTime = (tomorrowTimes.first['fajr'] ?? '').toString();
      final parts = fajrTime.split(':');
      if (parts.length < 2) return;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final nextPrayerTime = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        hour,
        minute,
      );
      final diff = nextPrayerTime.difference(now);

      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;

      if (!mounted) return;
      setState(() {
        nextPrayerName = 'İmsak';
        timeToNextPrayer =
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      });
    } catch (e) {
      print('❌ Yarın namaz vakti alma hatası: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        currentLocation = 'Konum alınıyor...';
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          currentLocation = 'Konum servisi kapalı - Ayarlardan açınız';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        await _checkLocationPermissionStatus();

        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            currentLocation = 'Konum izni reddedildi';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          currentLocation = 'Konum izni kalıcı reddedildi - Ayarlardan açınız';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (!mounted) return;
      setState(() {
        currentPosition = position;
      });

      await _getPlaceNameAndSave(position.latitude, position.longitude);
    } catch (e) {
      print('❌ Konum alma hatası: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        currentLocation = 'Konum alınamadı: ${e.toString()}';
      });
    }
  }

  Future<void> _getPlaceNameAndSave(double lat, double lng) async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&accept-language=tr',
            ),
            headers: {'User-Agent': 'PrayerTimesApp/1.0'},
          )
          .timeout(const Duration(seconds: 10));

      String locationText =
          'Konum: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] ?? {};

        if (address['city'] != null ||
            address['town'] != null ||
            address['village'] != null) {
          locationText =
              address['city'] ?? address['town'] ?? address['village'] ?? '';
        }

        if (address['state'] != null && locationText.isNotEmpty) {
          locationText += ', ${address['state']}';
        }
        if (address['country'] != null && locationText.isNotEmpty) {
          locationText += ', ${address['country']}';
        }

        if (locationText.isEmpty || locationText.startsWith('Konum:')) {
          locationText =
              data['display_name']?.toString().split(',').take(2).join(', ') ??
              'Konum: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
        }
      }

      final locationId = await _saveLocationToDB(lat, lng, locationText);

      if (!mounted) return;
      setState(() {
        currentLocation = locationText;
      });

      await _fetchPrayerTimesFor30Days(lat, lng, locationId);
    } catch (e) {
      print('❌ Konum adı alma hatası: $e');
      final locationText =
          'Konum: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      final locationId = await _saveLocationToDB(lat, lng, locationText);

      if (!mounted) return;
      setState(() {
        currentLocation = locationText;
      });

      await _fetchPrayerTimesFor30Days(lat, lng, locationId);
    }
  }

  Future<int> _saveLocationToDB(
    double lat,
    double lng,
    String locationName,
  ) async {
    try {
      final db = _database;
      if (db == null) return -1;

      final now = DateTime.now().toIso8601String();

      final existing = await db.query(
        'locations',
        where: 'ABS(latitude - ?) < 0.01 AND ABS(longitude - ?) < 0.01',
        whereArgs: [lat, lng],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final locationId = _toInt(existing.first['id']) ?? -1;
        if (locationId == -1) return -1;

        await db.update(
          'locations',
          {'location_name': locationName, 'updated_at': now},
          where: 'id = ?',
          whereArgs: [locationId],
        );
        print('✅ Mevcut konum güncellendi: $locationId');
        return locationId;
      } else {
        final locationId = await db.insert('locations', {
          'latitude': lat,
          'longitude': lng,
          'location_name': locationName,
          'created_at': now,
          'updated_at': now,
        });
        print('✅ Yeni konum kaydedildi: $locationId');
        return locationId;
      }
    } catch (e) {
      print('❌ Konum kaydetme hatası: $e');
      return -1;
    }
  }

  Future<void> _fetchPrayerTimesFor30Days(
    double lat,
    double lng,
    int locationId, {
    bool background = false,
  }) async {
    if (_isFetching) {
      print('⏳ Zaten veri çekiliyor, tekrar başlatılmadı');
      return;
    }
    _isFetching = true;

    try {
      if (!background && mounted) {
        setState(() {
          isLoading = true;
        });
      }

      print(
        '🕌 30 günlük namaz vakitleri alınıyor... (background=$background)',
      );

      final startDate = DateTime.now();
      final futures = <Future<void>>[];

      // Aynı anda 30 istek yoğun olabilir. İstersen 10-10 batch yaparız.
      for (int i = 0; i < 30; i++) {
        final targetDate = startDate.add(Duration(days: i));
        futures.add(
          _fetchAndSaveDayPrayerTimes(lat, lng, locationId, targetDate),
        );
      }

      await Future.wait(futures);

      await _loadTodayPrayerTimes(locationId);

      if (!background && mounted) {
        setState(() {
          isLoading = false;
          isDataFromCache = false;
        });
      }

      print('✅ 30 günlük veri başarıyla kaydedildi');
    } catch (e) {
      print('❌ 30 günlük veri alma hatası: $e');

      if (!background && mounted) {
        setState(() {
          isLoading = false;
        });
      }

      _showErrorSnackBar(
        'Namaz vakitleri alınamadı. İnternet bağlantınızı kontrol edin.',
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _fetchAndSaveDayPrayerTimes(
    double lat,
    double lng,
    int locationId,
    DateTime date,
  ) async {
    try {
      final db = _database;
      if (db == null) return;

      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final response = await http
          .get(
            Uri.parse(
              'https://api.aladhan.com/v1/timings/$dateStr?latitude=$lat&longitude=$lng&method=13&adjustment=1',
            ),
            headers: {'User-Agent': 'PrayerTimesApp/1.0'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return;

      final data = json.decode(response.body);
      if (data['code'] != 200 || data['data'] == null) return;

      final timings = data['data']['timings'];
      final dbDate = DateFormat('yyyy-MM-dd').format(date);

      await db.insert('prayer_times', {
        'location_id': locationId,
        'date': dbDate,
        'fajr': timings['Fajr']?.toString().substring(0, 5) ?? '00:00',
        'sunrise': timings['Sunrise']?.toString().substring(0, 5) ?? '00:00',
        'dhuhr': timings['Dhuhr']?.toString().substring(0, 5) ?? '00:00',
        'asr': timings['Asr']?.toString().substring(0, 5) ?? '00:00',
        'maghrib': timings['Maghrib']?.toString().substring(0, 5) ?? '00:00',
        'isha': timings['Isha']?.toString().substring(0, 5) ?? '00:00',
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // sessiz geçiyoruz ama log bırakıyoruz
      print('❌ ${date.day}/${date.month} için veri alma hatası: $e');
    }
  }

  Future<void> _loadTodayPrayerTimes(int locationId) async {
    try {
      final db = _database;
      if (db == null) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final result = await db.query(
        'prayer_times',
        where: 'location_id = ? AND date = ?',
        whereArgs: [locationId, today],
        limit: 1,
      );

      if (result.isEmpty) return;

      final times = result.first;

      final newPrayerTimes = {
        'Fajr': (times['fajr'] ?? '').toString(),
        'Sunrise': (times['sunrise'] ?? '').toString(),
        'Dhuhr': (times['dhuhr'] ?? '').toString(),
        'Asr': (times['asr'] ?? '').toString(),
        'Maghrib': (times['maghrib'] ?? '').toString(),
        'Isha': (times['isha'] ?? '').toString(),
      };

      if (!mounted) return;
      setState(() {
        prayerTimes = newPrayerTimes;
        isLoading = false;
        isDataFromCache = false;
      });

      _calculateNextPrayer();

      // ✅ Widget'a kaydet
      await _savePrayerTimesToAppGroup(
        newPrayerTimes.map((k, v) => MapEntry(k, v)),
      );
      print('✅ Widget\'a namaz vakitleri kaydedildi');
    } catch (e) {
      print('❌ Bugün verilerini yükleme hatası: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  static const _widgetChannel = MethodChannel('net.dilara.social/widget');

  Future<void> _savePrayerTimesToAppGroup(Map<String, String> times) async {
    try {
      await _widgetChannel.invokeMethod('savePrayerTimes', {
        'fajr': times['Fajr'] ?? '',
        'sunrise': times['Sunrise'] ?? '',
        'dhuhr': times['Dhuhr'] ?? '',
        'asr': times['Asr'] ?? '',
        'maghrib': times['Maghrib'] ?? '',
        'isha': times['Isha'] ?? '',
        'location': currentLocation,
        'date': DateFormat('dd.MM.yyyy').format(DateTime.now()),
      });
      print('✅ App Group\'a kaydedildi, widget güncellendi');
    } catch (e) {
      print('❌ App Group kayıt hatası: $e');
    }
  }

  Future<Map<String, String>?> _getPrayerTimesForDate(DateTime date) async {
    try {
      final db = _database;
      if (db == null) return null;

      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final locations = await db.query(
        'locations',
        orderBy: 'updated_at DESC',
        limit: 1,
      );
      if (locations.isEmpty) return null;

      final locationId = _toInt(locations.first['id']);
      if (locationId == null) return null;

      final result = await db.query(
        'prayer_times',
        where: 'location_id = ? AND date = ?',
        whereArgs: [locationId, dateStr],
        limit: 1,
      );
      if (result.isEmpty) return null;

      return {
        'Fajr': (result.first['fajr'] ?? '').toString(),
        'Sunrise': (result.first['sunrise'] ?? '').toString(),
        'Dhuhr': (result.first['dhuhr'] ?? '').toString(),
        'Asr': (result.first['asr'] ?? '').toString(),
        'Maghrib': (result.first['maghrib'] ?? '').toString(),
        'Isha': (result.first['isha'] ?? '').toString(),
      };
    } catch (e) {
      print('❌ Namaz vakitleri alınırken hata: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getNext5DaysPrayers() async {
    // Sen zaten DatabaseHelper kullanıyorsun; aynı DB dosyasını işaret ettiğini varsayıyorum.
    final db = await DatabaseHelper().database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await db.rawQuery(
      '''
      SELECT * FROM prayer_times
      WHERE date > ?
      ORDER BY date ASC
      LIMIT 5
      ''',
      [today],
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headingFontSize = screenWidth < 350 ? 10.0 : 12.0;
    final cellFontSize = screenWidth < 350 ? 10.0 : 12.0;
    final iconSize = screenWidth < 350 ? 24.0 : 32.0;

    return Scaffold(
      body: Stack(
        children: [
          if (!locationPermissionGranted)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_off, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Konum izni kapalı.\nNamaz vakitlerini görebilmek için konum izni gerekir.",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final permission = await Geolocator.requestPermission();
                        if (!mounted) return;
                        setState(() {
                          locationPermissionGranted =
                              permission == LocationPermission.whileInUse ||
                              permission == LocationPermission.always;
                        });
                        if (locationPermissionGranted) {
                          _getCurrentLocation();
                        }
                      },
                      child: const Text(
                        "İzin Ver",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned.fill(
            child: Image.asset(
              'assets/img/mountain_bg.png',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.3),
              colorBlendMode: BlendMode.darken,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: SafeArea(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    '$nextPrayerName ezanına kalan',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    timeToNextPrayer,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: Text(
                                    currentLocation.split(',').first,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.white30,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        DateFormat('dd').format(DateTime.now()),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'EEEE',
                                          'tr_TR',
                                        ).format(DateTime.now()),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'yyyy',
                                        ).format(DateTime.now()),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 60,
                                  color: Colors.white30,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Yerel saat',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        currentTime,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            Wrap(
                              alignment: WrapAlignment.spaceEvenly,
                              spacing: 6,
                              runSpacing: 10,
                              children: [
                                _buildPrayerIcon(
                                  'İmsak',
                                  Icons.nights_stay,
                                  prayerTimes?['Fajr'] ?? '--:--',
                                  isActive: nextPrayerName == 'İmsak',
                                  iconSize: iconSize,
                                ),
                                _buildPrayerIcon(
                                  'Güneş',
                                  Icons.wb_sunny,
                                  prayerTimes?['Sunrise'] ?? '--:--',
                                  isActive: nextPrayerName == 'Güneş',
                                  iconSize: iconSize,
                                ),
                                _buildPrayerIcon(
                                  'Öğle',
                                  Icons.wb_sunny,
                                  prayerTimes?['Dhuhr'] ?? '--:--',
                                  isActive: nextPrayerName == 'Öğle',
                                  iconSize: iconSize,
                                ),
                                _buildPrayerIcon(
                                  'İkindi',
                                  Icons.cloud,
                                  prayerTimes?['Asr'] ?? '--:--',
                                  isActive: nextPrayerName == 'İkindi',
                                  iconSize: iconSize,
                                ),
                                _buildPrayerIcon(
                                  'Akşam',
                                  Icons.nights_stay,
                                  prayerTimes?['Maghrib'] ?? '--:--',
                                  isActive: nextPrayerName == 'Akşam',
                                  iconSize: iconSize,
                                ),
                                _buildPrayerIcon(
                                  'Yatsı',
                                  Icons.nights_stay_outlined,
                                  prayerTimes?['Isha'] ?? '--:--',
                                  isActive: nextPrayerName == 'Yatsı',
                                  iconSize: iconSize,
                                ),
                              ],
                            ),

                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: getNext5DaysPrayers(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final days = snapshot.data!;
                                return Card(
                                  color: Colors.black54,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: screenWidth,
                                      ),
                                      child: DataTable(
                                        columnSpacing: 8,
                                        headingRowHeight: 28,
                                        dataRowHeight: 32,
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                              Colors.amber,
                                            ),
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              'Tarih',
                                              style: TextStyle(
                                                fontSize: headingFontSize,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'İmsak',
                                              style: TextStyle(
                                                fontSize: headingFontSize,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Güneş',
                                              style: TextStyle(
                                                fontSize: headingFontSize,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Öğle',
                                              style: TextStyle(
                                                fontSize: headingFontSize,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'İkindi',
                                              style: TextStyle(
                                                fontSize: headingFontSize,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Akşam',
                                              style: TextStyle(
                                                fontSize: headingFontSize,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Yatsı',
                                              style: TextStyle(
                                                fontSize: headingFontSize,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: days.map((d) {
                                          final date = d['date'] != null
                                              ? DateFormat('MM-dd').format(
                                                  DateTime.parse(d['date']),
                                                )
                                              : '';
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  date,
                                                  style: TextStyle(
                                                    fontSize: cellFontSize,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  d['fajr'] ?? '--',
                                                  style: TextStyle(
                                                    fontSize: cellFontSize,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  d['sunrise'] ?? '--',
                                                  style: TextStyle(
                                                    fontSize: cellFontSize,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  d['dhuhr'] ?? '--',
                                                  style: TextStyle(
                                                    fontSize: cellFontSize,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  d['asr'] ?? '--',
                                                  style: TextStyle(
                                                    fontSize: cellFontSize,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  d['maghrib'] ?? '--',
                                                  style: TextStyle(
                                                    fontSize: cellFontSize,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  d['isha'] ?? '--',
                                                  style: TextStyle(
                                                    fontSize: cellFontSize,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerIcon(
    String name,
    IconData icon,
    String time, {
    bool isActive = false,
    required double iconSize,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.amber : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.black : Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            color: isActive ? Colors.amber : Colors.white,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}
