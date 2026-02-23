import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'about_page.dart';

class GeneralSettingsPage extends StatefulWidget {
  const GeneralSettingsPage({Key? key}) : super(key: key);

  @override
  _GeneralSettingsPageState createState() => _GeneralSettingsPageState();
}

class _GeneralSettingsPageState extends State<GeneralSettingsPage> {
  bool isDarkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModeEnabled();
  }

  Future<void> _loadDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkModeEnabled = prefs.getBool('dark_mode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool newValue) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkModeEnabled = newValue;
      prefs.setBool('dark_mode', newValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Genel Ayarlar'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            _buildSettingCard(
              icon: Icons.info,
              title: 'Hakkında',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
            _buildSettingCard(
              icon: Icons.nightlight_round,
              title: 'Karanlık Mod',
              trailing: Switch(
                value: isDarkModeEnabled,
                onChanged: _toggleDarkMode,
              ),
              onTap: () => _toggleDarkMode(!isDarkModeEnabled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        leading: Icon(icon, color: Colors.blueGrey.shade700),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
