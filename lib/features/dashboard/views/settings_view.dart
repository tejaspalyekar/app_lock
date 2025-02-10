import 'package:app_lock/config/app_navigator.dart';
import 'package:app_lock/features/launcher/view/launcher_view.dart';
import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Map<String, dynamic>> settingsOptions = [
    {'icon': Icons.video_library, 'title': 'Video Editor'},
    {'icon': Icons.grid_on, 'title': 'Collage'},
    {'icon': Icons.content_cut, 'title': 'Clip'},
    {'icon': Icons.delete, 'title': 'Free Up Space'},
    {'icon': Icons.settings, 'title': 'Settings'},
    {'icon': Icons.help_outline, 'title': 'Help & Feedback'},
  ];
  String appVersion = "";

  @override
  void initState() {
    super.initState();
    getAppVersion();
  }

  getAppVersion() async {
    PackageInfo appDetails = await PackageInfo.fromPlatform();

    setState(() {
      appVersion = appDetails.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.home,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            // Navigator.of(context).pushReplacement(PageRouteBuilder(
            //   transitionDuration: Duration(milliseconds: 500),
            //   pageBuilder: (context, animation, secondaryAnimation) =>
            //       LauncherView(),
            // ));
          }),
      backgroundColor: Colors.black,
      bottomNavigationBar: SizedBox(
        height: 30,
        child: Align(
            alignment: Alignment.bottomCenter,
            child: Text("Version: $appVersion")),
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        itemCount: settingsOptions.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(settingsOptions[index]['icon'],
                color: const Color.fromARGB(255, 255, 255, 255)),
            title: Text(
              settingsOptions[index]['title'],
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              FirebaseLogger.logEvent('settings_clicked');
              if (index == 5) {
                pushScreen(context, '/homeScreen');
              }
            },
          );
        },
      ),
    );
  }
}
