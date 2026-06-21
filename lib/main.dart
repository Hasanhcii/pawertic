import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';

// Çekirdek Yapılar
import 'core/app_locale.dart';
import 'core/theme_notifier.dart';

// Servisler
import 'services/job_store.dart';
import 'services/user_store.dart';

// Sayfalar
import 'pages/login_page.dart';
import 'pages/admin_panel_page.dart';
import 'pages/bw_panel_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.backgroundHandler(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  await NotificationService.initialize();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  JobStore.startListening();
  UserStore.startListening();
  
  final prefs = await SharedPreferences.getInstance();
  AppLocale.lang = prefs.getString('lang') ?? 'tr';
  
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final int lastActive = prefs.getInt('lastActive') ?? 0;
  final String? savedUsername = prefs.getString('username');
  final String? role = prefs.getString('role');
  
  runApp(const MyAppRoot());
}

class MyAppRoot extends StatelessWidget {
  const MyAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pawertic',
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: ThemeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const LoginCheck(),
        );
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    bool isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      primaryColor: const Color(0xFF6200EE),
      scaffoldBackgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
      ),
      cardColor: isDark ? const Color(0xFF151515) : Colors.white,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EE), foregroundColor: Colors.white)
      )
    );
  }
}

class LoginCheck extends StatefulWidget {
  const LoginCheck({super.key});

  @override
  State<LoginCheck> createState() => _LoginCheckState();
}

class _LoginCheckState extends State<LoginCheck> {
  Widget _page = const Scaffold(body: Center(child: CircularProgressIndicator()));

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final int lastActive = prefs.getInt('lastActive') ?? 0;
    final String? savedUsername = prefs.getString('username');
    final String? role = prefs.getString('role');

    if (isLoggedIn && savedUsername != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastActive < 60 * 60 * 1000) { 
        setState(() {
          _page = role == 'admin' 
            ? const AdminPanelPage(username: 'Yönetici') 
            : BWPanelPage(username: savedUsername);
        });
        return;
      }
    }
    setState(() => _page = const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return _page;
  }
}
