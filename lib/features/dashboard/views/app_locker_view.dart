import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppLocker extends StatefulWidget {
  @override
  _AppLockerState createState() => _AppLockerState();
}

class _AppLockerState extends State<AppLocker> {
  final ValueNotifier<List<AppInfo>> _allApps = ValueNotifier([]);
  final ValueNotifier<Set<String>> _lockedApps = ValueNotifier({});
  bool _loading = true;
  String selectedAppPackageName = "";
  String selectedMapAppPackageName = "";
  Uint8List? selectedAppIcon;
  String selectedAppName = "";
  @override
  void initState() {
    super.initState();
    fetchApps();
  }

  Future<void> fetchApps() async {
    setState(() => _loading = true);

    try {
      // Fetch installed apps
      List<AppInfo> apps = await InstalledApps.getInstalledApps(true, true);
      _allApps.value = apps;

      // Fetch locked apps from SharedPreferences
      List<String>? lockedAppsList =
          await getPrefStringList(locked_app_list) ?? [];
      _lockedApps.value =
          lockedAppsList.toSet(); // Convert List to Set for quick lookup
    } catch (e) {
      debugPrint("Error fetching apps: $e");
    }

    setState(() => _loading = false);
  }

  void toggleLock(String packageName) async {
    Set<String> updatedLockedApps = Set.from(_lockedApps.value);

    if (updatedLockedApps.contains(packageName)) {
      updatedLockedApps.remove(packageName);
    } else {
      updatedLockedApps.add(packageName);
    }

    _lockedApps.value = updatedLockedApps;

    // Save updated locked apps list to shared preferences
    await setPrefStringList(locked_app_list, updatedLockedApps.toList());
  }

  void setAsDefaultLauncher() async {
    const intent = AndroidIntent(
      action: 'android.settings.HOME_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("App Locker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setAsDefaultLauncher();
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        alignment: Alignment.center,
        height: selectedAppPackageName.isEmpty
            ? 0
            : MediaQuery.of(context).size.height * 0.08,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.app_shortcut,
              color: Colors.black,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              "Please select a app to map your locked app",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ],
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              dividerColor: Colors.cyan,
              labelStyle: TextStyle(color: Colors.white),
              unselectedLabelColor: Color.fromARGB(255, 119, 119, 119),
              tabs: [
                Tab(icon: Icon(Icons.apps_sharp), text: "Unlocked Apps"),
                Tab(icon: Icon(Icons.lock), text: "Locked Apps"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildAppList(false),
                  buildAppList(true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAppList(bool locked) {
    return _loading
        ? const Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.cyan)))
        : ValueListenableBuilder<List<AppInfo>>(
            valueListenable: _allApps,
            builder: (context, allApps, _) {
              return ValueListenableBuilder<Set<String>>(
                valueListenable: _lockedApps,
                builder: (context, lockedApps, _) {
                  List<AppInfo> apps = allApps
                      .where((app) =>
                          locked == lockedApps.contains(app.packageName))
                      .toList();
                  return ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return GestureDetector(
                        onLongPress: () {
                          if (locked) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Confirm App unlocking"),
                                  content: const Text(
                                      "Are you sure you want to unlock this application?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Close dialog
                                      },
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 233, 233, 233)),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        toggleLock(app.packageName);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        "Confirm",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color.fromARGB(
                                                255, 255, 255, 255)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        },
                        child: ListTile(
                          onTap: () async {
                            if (locked) {
                              await LaunchApp.openApp(
                                  androidPackageName: app.packageName,
                                  openStore: false);
                              return;
                            }
                            if (selectedAppPackageName.isNotEmpty) {
                              if (selectedAppPackageName == app.packageName) {
                                setState(() {
                                  selectedAppIcon = null;
                                  selectedAppName = "";
                                  selectedAppPackageName = "";
                                });
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirm Mapping"),
                                    content: Text(
                                        "Are you sure you want to map ${app.name} with $selectedAppName?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close dialog
                                        },
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 233, 233, 233)),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedMapAppPackageName =
                                                app.packageName;
                                          });
                                          Navigator.of(context)
                                              .pop(); // Close dialog after confirming
                                          Navigator.of(context)
                                              .push(MaterialPageRoute(
                                            builder: (context) => LockAppView(
                                                callBack: () {
                                                  setState(() {
                                                    selectedMapAppPackageName =
                                                        "";
                                                    selectedAppIcon = null;
                                                    selectedAppName = "";
                                                    selectedAppPackageName = "";
                                                  });
                                                  fetchApps();
                                                },
                                                appIconImage: selectedAppIcon,
                                                selectedMapAppName:
                                                    selectedMapAppPackageName,
                                                selectedPackageName:
                                                    selectedAppPackageName,
                                                setAppLockPin: true,
                                                isPinAlreadySet: true),
                                          ));
                                        },
                                        child: const Text(
                                          "Confirm",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255)),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else {
                              setState(() {
                                selectedAppPackageName = app.packageName;
                                selectedAppIcon = app.icon;
                                selectedAppName = app.name;
                              });
                            }
                          },
                          leading: Image.memory(app.icon!,
                              width: 40,
                              height: 40,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.android, size: 40)),
                          title: Text(app.name),
                          trailing: Icon(
                              color: locked
                                  ? Colors.white
                                  : selectedAppPackageName.isNotEmpty
                                      ? selectedAppPackageName ==
                                              app.packageName
                                          ? Colors.green[400]
                                          : Colors.white
                                      : Colors.white,
                              locked
                                  ? Icons.lock
                                  : selectedAppPackageName.isNotEmpty
                                      ? selectedAppPackageName ==
                                              app.packageName
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.lock_open
                                      : Icons.lock_open),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
  }
}
