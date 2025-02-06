import 'dart:developer';

import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:provider/provider.dart';

class LauncherView extends StatefulWidget {
  const LauncherView({super.key});

  @override
  _LauncherViewState createState() => _LauncherViewState();
}

class _LauncherViewState extends State<LauncherView> {
  @override
  void initState() {
    super.initState();
    Provider.of<LauncherViewModel>(context, listen: false).loadApps();
  }

  void _showAppOptions(
      BuildContext context, Application app, LauncherViewModel value) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text('App Settings',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                DeviceApps.openAppSettings(app.packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('Uninstall', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  bool response =
                      await DeviceApps.uninstallApp(app.packageName);
                  // Wait a bit before checking if the app is still installed
                  await Future.delayed(const Duration(seconds: 2));

                  // Check if the app is still installed
                  Application? checkApp =
                      await DeviceApps.getApp(app.packageName, false);
                  if (checkApp == null) {
                    setState(() {
                      value.apps!.removeWhere(
                          (element) => element.packageName == app.packageName);
                    });
                  }
                } catch (e) {
                  log(e.toString());
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LauncherViewModel>(
      builder: (context, value, child) => WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Container(
          margin: const EdgeInsets.only(top: 30),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: value.apps == null
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.cyan),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(10),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5, // 4 apps per row
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: value.apps!.length,
                      itemBuilder: (context, index) {
                        Application app = value.apps![index];

                        return GestureDetector(
                          onTap: () async {
                            if (app.packageName != "com.gallery.app_lock") {
                              DeviceApps.openApp(app.packageName);
                            } else {
                              bool pinStatus =
                                  await getPrefBool(is_pin_set) ?? false;
                              Navigator.of(context).push(DialogRoute(
                                context: context,
                                builder: (context) => LockAppView(
                                    isPinAlreadySet: pinStatus,
                                    callBack: () {}),
                              ));
                            }
                          },
                          onLongPress: () =>
                              app.packageName != "com.gallery.app_lock"
                                  ? _showAppOptions(context, app, value)
                                  : null,
                          child: Column(
                            children: [
                              Container(
                                child: app is ApplicationWithIcon
                                    ? Image.memory(
                                        app.icon,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.contain,
                                      )
                                    : const Icon(Icons.android,
                                        size: 50, color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                app.appName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
