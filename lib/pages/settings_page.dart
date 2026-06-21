import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.t('settings'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            decoration: BoxDecoration(color: isDark ? const Color(0xFF151515) : Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              ListTile(leading: const Icon(Icons.language, color: Color(0xFF6200EE)), title: Text(AppLocale.t('lang')), subtitle: Text(AppLocale.lang == 'tr' ? 'Türkçe' : 'English'), trailing: const Icon(Icons.chevron_right), onTap: () => _showLangDialog()),
              const Divider(height: 1),
              ListTile(
                leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: const Color(0xFF6200EE)),
                title: Text(AppLocale.t('theme')),
                subtitle: Text(isDark ? AppLocale.t('dark_theme') : AppLocale.t('light_theme')),
                trailing: Switch(value: isDark, activeColor: const Color(0xFF6200EE), onChanged: (v) { themeNotifier.toggle(); setState(() {}); }),
              ),
            ]),
          ),
        ])
      )
    );
  }
  void _showLangDialog() { showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 20), ListTile(leading: const Text("🇹🇷", style: TextStyle(fontSize: 24)), title: const Text("Türkçe"), onTap: () => _changeLang('tr')), ListTile(leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)), title: const Text("English"), onTap: () => _changeLang('en')), const SizedBox(height: 20)])); }
  void _changeLang(String code) async { AppLocale.lang = code; final prefs = await SharedPreferences.getInstance(); await prefs.setString('lang', code); if (!mounted) return; Navigator.pop(context); setState(() {}); }
}
