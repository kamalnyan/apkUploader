import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Helper class for managing local notifications
class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static final NotificationHelper _instance = NotificationHelper._internal();
  
  /// Singleton factory constructor
  factory NotificationHelper() => _instance;
  
  /// Private constructor
  NotificationHelper._internal();
  
  /// Initialize notifications
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
  }
  
  /// Show APK download notification
  static Future<void> showDownloadNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'apk_download_channel',
      'APK Download',
      channelDescription: 'Notifications for APK download progress',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: progress < 100,
      autoCancel: progress >= 100,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      id,
      title,
      body,
      details,
    );
  }
  
  /// Show installation progress notification
  static Future<void> showInstallationNotification({
    required int id,
    required String title,
    required String body,
    bool isComplete = false,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'apk_install_channel',
      'APK Installation',
      channelDescription: 'Notifications for APK installation',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: !isComplete,
      autoCancel: isComplete,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      id,
      title,
      body,
      details,
    );
  }
  
  /// Cancel a notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
} 