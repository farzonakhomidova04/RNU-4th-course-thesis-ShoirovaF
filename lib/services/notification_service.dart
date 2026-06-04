import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission (mostly for iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission for notifications');
      
      // Subscribe to general topic to receive global announcements
      if (!kIsWeb) {
        await _fcm.subscribeToTopic('all_users');
      }

      // Handle background messages (setup is typically in main.dart but we keep it simple here)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground message: \${message.notification?.title}');
        // Here we could show a local notification or an in-app SnackBar
      });
    }
  }
}
