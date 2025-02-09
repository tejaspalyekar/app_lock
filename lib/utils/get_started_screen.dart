import 'dart:developer';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view/launcher_view.dart';
import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:app_lock/utils/customs/custom_textButton.dart';
import 'package:app_lock/utils/notification_service_handler.dart';

import 'package:flutter/material.dart';

class GetStatedScreen extends StatefulWidget {
  const GetStatedScreen({super.key});

  @override
  State<GetStatedScreen> createState() => _GetStatedScreenState();
}

class _GetStatedScreenState extends State<GetStatedScreen> {
  @override
  void initState() {
    super.initState();
  }

  void setAsDefaultLauncher() async {
    FirebaseLogger.logEvent("Setting as default launcher");
    try {
      const intent = AndroidIntent(
        action: 'android.settings.HOME_SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      setPrefBool("isFirstTime", true);
      await intent.launch();
    } catch (e) {
      log(e.toString());
    }

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => LauncherView(
        fromGetStartedScreen: false,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomTextButton(
          callBackFun: () {
            setAsDefaultLauncher();
          },
          btnTitle: "Get Stated!!"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: MediaQuery.of(context).size.height * 0.2,
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Gallery",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
