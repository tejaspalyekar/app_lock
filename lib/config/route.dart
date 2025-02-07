import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:app_lock/features/dashboard/views/gallery_view.dart';
import 'package:app_lock/features/dashboard/views/app_locker_view.dart';
import 'package:app_lock/features/launcher/view/launcher_view.dart';
import 'package:app_lock/utils/get_started_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:flutter/services.dart';

class InitialRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: getPrefBool(is_pin_set), // Ensure default value
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.cyan),
              ),
            ),
          ); // Loading indicator
        } else {
          return FutureBuilder<Widget>(
            future: checkAndSetDefaultLauncher(),
            builder: (context, launcherSnapshot) {
              if (launcherSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (launcherSnapshot.hasError) {
                return const Center(child: Text("Error loading launcher"));
              } else {
                return launcherSnapshot.data ?? const GetStatedScreen();
              }
            },
          );
        }
      },
    );
  }
}

class LauncherHelper {
  static const MethodChannel _channel = MethodChannel('app_lock/launcher');

  static Future<bool> isDefaultLauncher() async {
    try {
      final bool isDefault = await _channel.invokeMethod('isDefaultLauncher');
      return isDefault;
    } catch (e) {
      print("Error checking default launcher: $e");
      return false;
    }
  }
}

Future<StatefulWidget> checkAndSetDefaultLauncher() async {
  bool isDefault = await LauncherHelper.isDefaultLauncher();
  bool isfirstTime = await getPrefBool("isFirstTime") ?? false;
  if (isDefault) {
    return LauncherView(
      fromGetStartedScreen: isfirstTime,
    );
  } else {
    return const GetStatedScreen();
  }
}

Map<String, Widget Function(BuildContext)> appRoutes = {
  '/': (context) => InitialRoute(), // Use the async wrapper
  '/galleryScreen': (context) => const GalleryView(),
  '/homeScreen': (context) => AppLocker(),
  '/launcherView': (context) => LauncherView(),
  '/gettingStarted': (context) => const GetStatedScreen()
};
