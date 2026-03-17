import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight service that persists user preferences.
///
/// The app uses this to drive global settings like dark mode.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _darkModeKey = 'dark_mode';
  static const _notificationsKey = 'notifications_enabled';

  final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);
  final ValueNotifier<bool> notificationsEnabled = ValueNotifier<bool>(true);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool(_darkModeKey) ?? false;
    notificationsEnabled.value = prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
    isDarkMode.value = value;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    notificationsEnabled.value = value;
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: SettingsService.instance.isDarkMode,
              builder: (context, isDarkMode, _) {
                return SwitchListTile(
                  title: const Text('Dark mode'),
                  subtitle: const Text('Use a darker theme for the app'),
                  value: isDarkMode,
                  onChanged: (value) {
                    SettingsService.instance.setDarkMode(value);
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: SettingsService.instance.notificationsEnabled,
              builder: (context, enabled, _) {
                return SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle:
                      const Text('Enable crash alerts and status updates'),
                  value: enabled,
                  onChanged: (value) {
                    SettingsService.instance.setNotificationsEnabled(value);
                  },
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              subtitle: const Text('App version and credits'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Sentinel',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 Sentinel',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
