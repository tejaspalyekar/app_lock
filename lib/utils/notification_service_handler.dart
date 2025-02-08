import 'package:flutter/services.dart';

class NotificationPermissionHandler {
  static const platform = MethodChannel('app_locker/notifications');

  static Future<void> requestNotificationAccess() async {
    try {
      await platform.invokeMethod('requestNotificationAccess');
    } catch (e) {
      print("Error requesting notification access: $e");
    }
  }
}



