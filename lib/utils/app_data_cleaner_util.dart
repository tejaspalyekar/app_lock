import 'package:flutter/services.dart';

class TargetAppDataCleaner {
  static const platform = MethodChannel('target_app_data_cleaner');

  static Future<bool> clearTargetAppData(String packageName) async {
    try {
      final bool result = await platform.invokeMethod('clearTargetAppData', {
        'packageName': packageName,
      });
      return result;
    } on PlatformException catch (e) {
      print('Error clearing target app data: ${e.message}');
      return false;
    }
  }
}
