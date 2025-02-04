import 'package:app_lock/features/dashboard/views/gallery_view.dart';
import 'package:app_lock/features/dashboard/views/app_locker_view.dart';
import 'package:app_lock/features/launcher/view/launcher_view.dart';
import 'package:app_lock/utils/get_started_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';

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
          )); // Loading indicator
        } else {
          if (snapshot.data ?? false) {
            //    return LockAppView(
            //   isPinAlreadySet: snapshot.data ?? false,
            //   callBack: () {},
            // );
            return LauncherView();
          } else {
            return const GetStatedScreen();
          }
        }
      },
    );
  }
}

Map<String, Widget Function(BuildContext)> appRoutes = {
  '/': (context) => InitialRoute(), // Use the async wrapper
  '/galleryScreen': (context) => const GalleryView(),
  '/homeScreen': (context) => AppLocker(),
  '/launcherView': (context) => const LauncherView(),
  '/gettingStarted': (context) => const GetStatedScreen()
};
