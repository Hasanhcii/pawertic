import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_locale.dart';
import '../core/theme_notifier.dart';
import '../widgets/notify.dart';
import 'admin_panel_page.dart';
import 'bw_panel_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController(), passCtrl = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    final user = userCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      Notify.show(context, AppLocale.t('required_fields'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Önce Manuel Admin Kontrolü (Yedek olarak)
      if (user == 'admin' && pass == 'admin123') {
        await _saveLoginSession('Yönetici', 'admin');
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const AdminPanelPage(username: 'Yönetici')));
        return;
      }

      // 2. Firestore üzerinden kullanıcıyı sorgula
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (userData['password'] == pass) {
          await _saveLoginSession(user, userData['role']);
          if (!mounted) return;
          if (userData['role'] == 'admin') {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => AdminPanelPage(username: user)));
          } else {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => BWPanelPage(username: user)));
          }
        } else {
          Notify.show(context, 'Hatalı Şifre!', isError: true);
        }
      } else {
        Notify.show(context, 'Kullanıcı Bulunamadı!', isError: true);
      }
    } catch (e) {
      Notify.show(context, "Bağlantı Hatası: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveLoginSession(String username, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('role', role);
    await prefs.setInt('lastActive', DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = ThemeNotifier.isDarkMode;
    return Scaffold(
      body: Container(
        decoration: isDark 
          ? const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.black, Color(0xFF1A0033), Color(0xFF330066)])) 
          : const BoxDecoration(color: Color(0xFFF5F5F5)),
        child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('PAWERTIC', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 3, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 50),
          TextField(controller: userCtrl, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(hintText: AppLocale.t('user'), hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: isDark ? const Color(0xFF151515) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)))),
          const SizedBox(height: 15),
          TextField(controller: passCtrl, obscureText: true, style: TextStyle(color: isDark ? Colors.white : Colors.black), decoration: InputDecoration(hintText: AppLocale.t('pass'), hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: isDark ? const Color(0xFF151515) : Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)))),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(shape: const StadiumBorder()), onPressed: _isLoading ? null : _login, child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(AppLocale.t('login'), style: const TextStyle(fontWeight: FontWeight.bold))))
        ])),
      ),
    );
  }
}
