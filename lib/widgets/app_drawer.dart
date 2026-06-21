import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../data/vehicle_data.dart';
import '../pages/admin_panel_page.dart';
import '../pages/bw_panel_page.dart';
import '../pages/user_management_page.dart';
import '../pages/profile_page.dart';
import '../pages/settings_page.dart';
import '../pages/category_jobs_page.dart';
import '../pages/login_page.dart';
import '../pages/history_page.dart';

class AppDrawer extends StatefulWidget {
  final String username;
  const AppDrawer({required this.username, super.key});
  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? profilePicPath, role;
  @override
  void initState() { super.initState(); _loadData(); }
  void _loadData() async { 
    final prefs = await SharedPreferences.getInstance(); 
    setState(() { 
      profilePicPath = prefs.getString('profile_pic'); 
      role = prefs.getString('role'); 
    }); 
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'MONTAJ': return Icons.build_circle_outlined;
      case 'DEMONTAJ': return Icons.remove_circle_outline;
      case 'SERVİS': return Icons.home_repair_service_outlined;
      case 'KONTROL': return Icons.fact_check_outlined;
      case 'KAMERA MONTAJ': return Icons.videocam_outlined;
      case 'AKSESUAR': return Icons.extension_outlined;
      default: return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Drawer(
      backgroundColor: isDark ? Colors.black : Colors.white,
      child: SafeArea(child: Column(children: [
        Expanded(child: ListView(padding: EdgeInsets.zero, children: [
          const SizedBox(height: 40),
          GestureDetector(onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => ProfilePage(username: widget.username))).then((_) => _loadData()); }, child: Column(children: [Container(width: 90, height: 90, decoration: BoxDecoration(color: isDark ? Colors.white : const Color(0xFFF5F5F5), shape: BoxShape.circle, image: profilePicPath != null ? DecorationImage(image: FileImage(File(profilePicPath!)), fit: BoxFit.cover) : null, border: isDark ? null : Border.all(color: Colors.black12)), child: profilePicPath == null ? Icon(Icons.person, size: 60, color: isDark ? Colors.black : Colors.grey) : null), const SizedBox(height: 15), Text(widget.username, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))])),
          const SizedBox(height: 30),
          
          _item(Icons.home_outlined, AppLocale.t('home'), () {
             Navigator.pop(context);
             if (role == 'admin') {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminPanelPage(username: 'Yönetici')));
             } else {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => BWPanelPage(username: widget.username)));
             }
          }),

          // İŞ EMİRLERİ
          Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
            leading: const Icon(Icons.assignment_outlined, color: Color(0xFF6200EE)), 
            title: Text(role == 'admin' ? "İŞ EMİRLERİ" : "İŞ EMİRLERİM", style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)), 
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 40), 
                leading: const Icon(Icons.history, size: 20, color: Colors.blueGrey),
                title: Text(AppLocale.t('done_jobs'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)), 
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryPage())); }
              ),
              ...jobTypes.map((type) => ListTile(
                contentPadding: const EdgeInsets.only(left: 40), 
                leading: Icon(_getIconForType(type), size: 20, color: const Color(0xFF6200EE).withOpacity(0.7)),
                title: Text(type, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)), 
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => CategoryJobsPage(category: type))); }
              )),
            ]
          )),

          if (role == 'admin') Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
            leading: const Icon(Icons.people_outline, color: Color(0xFF6200EE)),
            title: Text(AppLocale.t('users').toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
            children: [
              ListTile(
                contentPadding: const EdgeInsets.only(left: 40), 
                leading: const Icon(Icons.manage_accounts_outlined, size: 20, color: Colors.blue),
                title: Text(AppLocale.t('manage_users'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)), 
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const UserManagementPage())); }
              ),
              ListTile(
                contentPadding: const EdgeInsets.only(left: 40), 
                leading: const Icon(Icons.tune_outlined, size: 20, color: Colors.orange),
                title: Text(AppLocale.t('settings'), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)), 
                onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsPage())); }
              ),
            ],
          )),

          if (role != 'admin') _item(Icons.settings_outlined, AppLocale.t('settings'), () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsPage())); }),
        ])),

        _item(Icons.logout, AppLocale.t('logout'), () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);
          await prefs.remove('role');
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LoginPage()), (r) => false);
        }),
        const SizedBox(height: 10)
      ])),
    );
  }
  Widget _item(IconData i, String t, VoidCallback o) => ListTile(leading: Icon(i, color: const Color(0xFF6200EE), size: 24), title: Text(t, style: TextStyle(color: ThemeNotifier.isDarkMode ? Colors.white : Colors.black, fontSize: 15, fontWeight: FontWeight.w500)), onTap: o);
}
