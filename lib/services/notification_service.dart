import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. İzin İste (Android 13+ ve iOS için kritik)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Bildirim izni verildi.');
    } else {
      debugPrint('Bildirim izni reddedildi.');
    }

    // 2. FCM Token Al (Test için çok önemli!)
    String? token = await _fcm.getToken();
    debugPrint("---------------------------------------");
    debugPrint("FCM TOKEN: $token");
    debugPrint("---------------------------------------");

    // 3. Android Yerel Bildirim Ayarları ve Kanal Oluşturma
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    // Android için yüksek öncelikli bildirim kanalı
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'Yüksek Öncelikli Bildirimler', // title
      description: 'Bu kanal önemli duyurular için kullanılır.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Topic'e Abone Ol
    await _fcm.subscribeToTopic('announcements');

    // 5. Uygulama Ön Plandayken Gelen Mesajları Dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  static Future<void> backgroundHandler(RemoteMessage message) async {
    debugPrint("Arka planda mesaj alındı: ${message.messageId}");
  }
}
