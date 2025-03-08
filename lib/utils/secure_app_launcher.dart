import 'package:flutter/services.dart';

class SecureAppLauncher {
  static const platform = MethodChannel('app_lock/secure_launch');

  Future<void> launchSecureApp(String packageName, bool isLocked) async {
    try {
      // Launch the app
      await platform.invokeMethod('launchSecureApp', {
        'packageName': packageName,
        'isLocked': isLocked,
      });

      // If app is locked, immediately set FLAG_SECURE
      if (isLocked) {
        await platform.invokeMethod('setSecureFlag', {
          'packageName': packageName,
        });
      }
    } catch (e) {
      print('Error launching app: $e');
    }
  }
}
