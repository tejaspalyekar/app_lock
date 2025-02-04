import 'package:app_lock/config/app_navigator.dart';
import 'package:app_lock/features/launcher/view/launcher_view.dart';
import 'package:app_lock/utils/customs/custom_textButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class GetStatedScreen extends StatelessWidget {
  const GetStatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomTextButton(
          callBackFun: () {
            pushReplacement(context, '/launcherView');
          },
          btnTitle: "Get Stated!!"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_sharp,
              size: MediaQuery.of(context).size.height * 0.2,
            ),
            const SizedBox(height: 20),
            const Text(
              "Welcome to",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              "App lock Application",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
