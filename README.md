🕌 Dilara – Prayer Times & Notification App








Modern, lightweight and customizable Prayer Times & Notification App built with Flutter.

Designed for performance, clean UI and flexible notification management.

✨ Features

📍 Location-based prayer time calculation

🕌 Daily prayer schedule

🔔 Advanced notification system

🎵 Custom Azan sounds:

Mekke

Medine

Ayasofya

⏱ Pre-notification offsets (15 / 30 / 45 minutes)

☁ Firebase Cloud Messaging support

🌙 Background notification handling

🍎 iOS & 🤖 Android compatible

🏗 Architecture
lib/
 ├── core/
 │    ├── pages/
 │    │    ├── prayer_times_page.dart
 │    │    ├── notification_settings_page.dart
 │    │
 │    ├── utill/
 │    │    ├── notifications.dart
 │
assets/
 ├── sounds/
      ├── mekke.mp3
      ├── medine.mp3
      ├── ayasofya.mp3
📦 Dependencies

firebase_core

firebase_messaging

awesome_notifications

geolocator

shared_preferences

intl

🔊 Custom Notification Sounds
Android
android/app/src/main/res/raw/
iOS
ios/Runner/Sounds/

iOS requires .caf format for custom notification sounds.

🚀 Getting Started
1️⃣ Clone Repository
git clone https://github.com/MSaidKasap/dilaranetv2.git
cd dilara_app
2️⃣ Install Dependencies
flutter pub get
3️⃣ Configure Firebase

Add:

google-services.json → Android

GoogleService-Info.plist → iOS

Then run:

flutterfire configure
4️⃣ Run Project
flutter run
⚙ Versioning

pubspec.yaml

version: 40.0.0+1
🛠 Build
Android
flutter build appbundle
iOS
flutter build ios
📌 Roadmap

 iOS Widget Extension improvements

 Dynamic theme system

 More Azan sound packs

 Multi-language support

 Offline prayer calculation optimization

🤝 Contributing

Contributions are welcome.

Fork the repo

Create your branch (feature/new-feature)

Commit changes

Push to branch

Open a Pull Request

📄 License

This project is licensed under the MIT License.

👨‍💻 Author

Mustafa Said Kasap
Dilara Bilgisayar