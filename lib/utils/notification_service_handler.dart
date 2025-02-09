import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:flutter/services.dart';

class NotificationPermissionHandler {
  static const platform = MethodChannel('app_locker/notifications');

  static Future<void> requestNotificationAccess() async {
    FirebaseLogger.logEvent("RequestNotificationAccess");
    try {
      await platform.invokeMethod('requestNotificationAccess');
    } catch (e) {
      print("Error requesting notification access: $e");
    }
  }
}
