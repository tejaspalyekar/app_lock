import 'package:app_lock/config/app_navigator.dart';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class LauncherView extends StatefulWidget {
  const LauncherView({super.key});

  @override
  _LauncherViewState createState() => _LauncherViewState();
}

class _LauncherViewState extends State<LauncherView> {
  List<dynamic>? apps;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    List<dynamic> installedApps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true);
    //installedApps.add(app_lock); //app_lock = APP_LOCK
    setState(() {
      apps = installedApps;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: apps == null
          ? const Center(
              child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.cyan),
            ))
          : Container(
              margin: const EdgeInsets.only(top: 15),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 5 apps per row
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.8, // Adjusts height-to-width ratio
                  ),
                  itemCount: apps!.length,
                  itemBuilder: (context, index) {
                    Application app = apps![index];
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
                                isPinAlreadySet: pinStatus, callBack: () {}),
                          ));
                        }
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color:
                                  Colors.white10, // Light background for icons
                            ),
                            child: app.packageName != "com.gallery.app_lock"
                                ? Image.memory(
                                    (app as ApplicationWithIcon).icon,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                  )
                                : const SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Icon(
                                      Icons.image,
                                    )),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            app.packageName != "com.gallery.app_lock"
                                ? app.appName
                                : "My Gallery",
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
    );
  }
}
