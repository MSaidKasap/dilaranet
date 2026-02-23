import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

import '../menu/home_menu.dart';
import '../menu/menu.dart';
import '../pages/book/book1.dart';
import '../pages/category_posts_page.dart';
import '../pages/html/dilaranet.dart';
import '../pages/html/dilarayayinlari.dart';
import '../pages/prayer_times_page.dart';
import '../widget/HomePostsWidget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late SharedPreferences _preferences;
  late TabController _tabController;

  bool isDarkModeEnabled = false;
  bool _notificationAllowed = false;
  bool _locationAllowed = false;

  String appGroupID = "group.net.dilara.social";
  String iosWidgetName = "DilaraWidget";
  String androidWidgetName = "DilaraWidget";
  String dataKey = "text_from_flutter_app";

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
    _checkNotificationPermission();
    _checkLocationPermission(); // 🔥 Konum izni kontrolü eklendi

    _tabController = TabController(length: 6, vsync: this);
  }

  Future<void> _initSharedPreferences() async {
    _preferences = await SharedPreferences.getInstance();

    setState(() {
      isDarkModeEnabled = _preferences.getBool('dark_mode') ?? false;
    });
  }

  // -------------------------------
  // 🔔 Bildirim İzni Kontrol & İstek
  // -------------------------------
  Future<void> _checkNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    setState(() => _notificationAllowed = isAllowed);
  }

  Future<void> _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      bool granted = await AwesomeNotifications()
          .requestPermissionToSendNotifications();

      if (granted) {
        String? token = await FirebaseMessaging.instance.getToken();
        print("🔑 FCM Token: $token");
      }

      setState(() => _notificationAllowed = granted);
    }
  }

  // -------------------------------
  // 📍 Konum İzni Kontrol & İstek
  // -------------------------------
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    setState(() {
      _locationAllowed =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      bool allowed =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      setState(() {
        _locationAllowed = allowed;
      });

      print(allowed ? "📍 Konum izni verildi" : "❌ Konum izni reddedildi");
    } catch (e) {
      print('❌ Konum izni hatası: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveDarkModePreference(bool darkMode) {
    _preferences.setBool('dark_mode', darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkModeEnabled ? ThemeData.dark() : ThemeData.light(),
      home: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            title: Image.asset('assets/img/logo.png', width: 2000, height: 50),
            leading: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),

            // ---------------------------
            // 🔥 İzin Butonları Burada
            // ---------------------------
            actions: [
              // Dark Mode
              IconButton(
                icon: Icon(
                  isDarkModeEnabled ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  setState(() {
                    isDarkModeEnabled = !isDarkModeEnabled;
                  });
                  _saveDarkModePreference(isDarkModeEnabled);
                },
              ),

              // 🔔 Bildirim izni butonu
              if (!_notificationAllowed)
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined),
                  tooltip: "Bildirimleri Aç",
                  onPressed: () {
                    _requestNotificationPermission();
                  },
                ),

              // 📍 Konum izni butonu
              if (!_locationAllowed)
                IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  tooltip: "Konum İznini Aç",
                  onPressed: () {
                    _requestLocationPermission();
                  },
                ),
            ],

            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              unselectedLabelColor: const Color(0xff585861),
              indicatorColor: Colors.white,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Dilara'),
                Tab(text: 'Namaz Vakitleri'),
                Tab(text: 'Sevgi Bağı'),
                Tab(text: 'Soru Cevap'),
                Tab(text: 'Mağaza'),
                Tab(text: 'Soru Sor'),
              ],
            ),
          ),

          drawer: const MyDrawer(),

          body: TabBarView(
            controller: _tabController,
            children: const [
              HomePostsWidget(),
              PrayerTimesPage(),
              ContentPage(),
              CategoryPostsPage(categoryId: 12),
              Shop(),
              Question(),
            ],
          ),
        ),
      ),
    );
  }
}
