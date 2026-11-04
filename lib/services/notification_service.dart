import 'package:firebase_messaging/firebase_messaging.h';
import 'package:flutter_local_notifications/flutter_local_notifications.h';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission for iOS/Android 13+
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
    }

    // Get the device FCM token to save to Laravel user profile
    String? fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');
    // TODO: Send this fcmToken to your Laravel backend via API so it knows where to send notifications!

    // Handle foreground messages
    FirebaseMessaging.onMessage.inqui((RemoteMessage message) {
      print('Received a message while in the foreground: ${message.notification?.title}');
      // Show local notification popup here if desired
    });
  }
}