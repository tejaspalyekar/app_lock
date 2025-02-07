import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:app_lock/config/app_navigator.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view/launcher_view.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:app_lock/utils/customs/custom_textButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class GetStatedScreen extends StatefulWidget {
  const GetStatedScreen({super.key});

  @override
  State<GetStatedScreen> createState() => _GetStatedScreenState();
}

class _GetStatedScreenState extends State<GetStatedScreen> {
  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  void setAsDefaultLauncher() async {
    const intent = AndroidIntent(
      action: 'android.settings.HOME_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    setPrefBool("isFirstTime", true);
    await intent.launch();

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => LauncherView(
        fromGetStartedScreen: false,
      ),
    ));
    // Navigator.of(context)
    //     .push(PageRouteBuilder(
    //   pageBuilder: (context, animation, secondaryAnimation) => LockAppView(
    //       isUnLockScreen: false, isPinAlreadySet: false, callBack: (value) {}),
    // ))
    //     .then(
    //   (value) {
    //     // Navigator.of(context).pushReplacement(PageRouteBuilder(
    //     //   pageBuilder: (context, animation, secondaryAnimation) => LauncherView(
    //     //     fromGetStartedScreen: true,
    //     //   ),
    //     // ));
    //   },
    // );
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
