import 'dart:developer';
import 'dart:typed_data';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view/launcher_view.dart';
import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:app_lock/utils/notification_service_handler.dart';
import 'package:app_lock/utils/open_whatsapp_settings.dart';
import 'package:app_lock/utils/request_notification_permission_helper.dart';
import 'package:app_lock/utils/secure_app_launcher.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:provider/provider.dart';

class AppLocker extends StatefulWidget {
  @override
  _AppLockerState createState() => _AppLockerState();
}

class _AppLockerState extends State<AppLocker> {
  final NotificationPermissionHandler _permissionHandler =
      NotificationPermissionHandler();
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
    try {
      fetchApps();
      askForRistrictedPermissions();
    } catch (e) {
      log(e.toString());
    }
  }

  askForRistrictedPermissions() async {
    FirebaseLogger.logEvent("ask_for_restricted_permissions");
    const platform = MethodChannel('app_locker/notifications');
    final bool hasPermission =
        await platform.invokeMethod('checkNotificationPermission');
    if (!hasPermission) {
      _checkPermissions();
      requestNotificationPermissions(context);
    }
  }

  Future<void> _requestPermissions() async {
    await NotificationPermissionHandler.requestNotificationAccess();
  }

  Future<void> _checkPermissions() async {
    FirebaseLogger.logEvent("checkPermissions");
    // Check if we already have notification permissions
    const platform = MethodChannel('app_locker/notifications');
    try {
      final bool hasPermission =
          await platform.invokeMethod('checkNotificationPermission');
      if (!hasPermission) {
        // Optionally show a dialog explaining why we need permissions
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                "Permissions Required",
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                  "To hide notifications for locked apps, this app needs notification access permission. Please grant necessary permission"),
              actions: [
                TextButton(
                  onPressed: () {
                    FirebaseLogger.logEvent(
                        "Notification listener permission cancelled");
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Later",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                TextButton(
                  style: ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(Colors.cyan.withOpacity(0.1))),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    FirebaseLogger.logEvent(
                        "Notification listener permission setting opened");
                    await _requestPermissions();
                  },
                  child: const Text(
                    "Grant Permission",
                    style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Error checking notification permission: $e");
    }
  }

  Future<void> fetchApps() async {
    FirebaseLogger.logEvent("fetch_apps");
    setState(() => _loading = true);

    try {
      // Fetch installed apps
      List<AppInfo> apps = await InstalledApps.getInstalledApps(false, true);
      _allApps.value = apps;

      // Fetch locked apps from SharedPreferences
      List<String>? lockedAppsList =
          await getPrefStringList(locked_app_list) ?? [];
      FirebaseLogger.logEvent('locked_app_list', parameters: {
        'locked_app_list_size': lockedAppsList.toString(),
      });
      _lockedApps.value =
          lockedAppsList.toSet(); // Convert List to Set for quick lookup
    } catch (e) {
      debugPrint("Error fetching apps: $e");
    }

    setState(() => _loading = false);
  }

  Widget _buildStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  EnablePermissionDialog(context, PackageName) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_off,
                  color: Color.fromARGB(255, 248, 97, 97)),
              SizedBox(width: 10),
              Text(
                'Enable Floating Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Follow these steps to enable floating notifications for ${selectedAppName}:',
                style: const TextStyle(fontSize: 13),
              ),
              selectedAppPackageName == "com.whatsapp" ||
                      selectedAppPackageName == "com.whatsapp.w4b"
                  ? Column(
                      children: [
                        const SizedBox(height: 15),
                        _buildStep(Icons.settings, 'Tap "Go to Settings".'),
                        _buildStep(Icons.call, 'Select "Call Notifications".'),
                        _buildStep(Icons.arrow_downward,
                            'Scroll down to "Floating Notifications".'),
                        _buildStep(Icons.toggle_off, 'Select "ON".'),
                      ],
                    )
                  : Column(
                      children: [
                        _buildStep(Icons.arrow_downward,
                            'Scroll down to "Floating Notifications".'),
                        _buildStep(Icons.toggle_off, 'Select "ON".'),
                      ],
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                toggleLock(PackageName);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await openWhatsAppNotificationSettings(selectedAppPackageName);
                toggleLock(PackageName);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Go to Settings'),
            ),
          ],
        );
      },
    );
  }

  notificationPermissionDialog(context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_off,
                  color: Color.fromARGB(255, 248, 97, 97)),
              SizedBox(width: 10),
              Text(
                'Disable Floating Notifications',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Follow these steps to disable floating notifications for ${selectedAppName}:',
                style: const TextStyle(fontSize: 13),
              ),
              selectedAppPackageName == "com.whatsapp" ||
                      selectedAppPackageName == "com.whatsapp.w4b"
                  ? Column(
                      children: [
                        const SizedBox(height: 15),
                        _buildStep(Icons.settings, 'Tap "Go to Settings".'),
                        _buildStep(Icons.call, 'Select "Call Notifications".'),
                        _buildStep(Icons.arrow_downward,
                            'Scroll down to "Floating Notifications".'),
                        _buildStep(Icons.toggle_off, 'Select "Off".'),
                      ],
                    )
                  : Column(
                      children: [
                        _buildStep(Icons.arrow_downward,
                            'Scroll down to "Floating Notifications".'),
                        _buildStep(Icons.toggle_off, 'Select "Off".'),
                      ],
                    ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseLogger.logEvent(
                  "floating_notification_cancel",
                );
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                FirebaseLogger.logEvent("open_floating_notification_setting",
                    parameters: {
                      "selected_package_name": selectedAppPackageName,
                    });
                await openWhatsAppNotificationSettings(selectedAppPackageName);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => LockAppView(
                      callBack: () {
                        setState(() {
                          selectedMapAppPackageName = "";
                          selectedAppIcon = null;
                          selectedAppName = "";
                          selectedAppPackageName = "";
                        });
                        fetchApps();
                      },
                      appIconImage: selectedAppIcon,
                      selectedMapAppName: selectedMapAppPackageName,
                      selectedPackageName: selectedAppPackageName,
                      setAppLockPin: true,
                      isPinAlreadySet: true),
                ));
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Go to Settings'),
            ),
          ],
        );
      },
    );
  }

  void toggleLock(String packageName) async {
    Set<String> updatedLockedApps = Set.from(_lockedApps.value);

    if (updatedLockedApps.contains(packageName)) {
      List<String> appDetail = await getPrefStringList(packageName) ?? [];
      if (appDetail.isNotEmpty) {
        String mappedPackageName = appDetail[1];
        updatedLockedApps.remove(packageName);
        updatedLockedApps.remove(mappedPackageName);
        removePrefData(packageName);
        removePrefData(mappedPackageName);
      }
    } else {
      updatedLockedApps.add(packageName);
    }

    _lockedApps.value = updatedLockedApps;

    // Save updated locked apps list to shared preferences
    await setPrefStringList(locked_app_list, updatedLockedApps.toList());
    Provider.of<LauncherViewModel>(context, listen: false).refreshApps(context);
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
      floatingActionButton: FloatingActionButton.small(
          backgroundColor: Colors.white,
          child: const Icon(
            Icons.home,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            // Navigator.of(context).pushReplacement(PageRouteBuilder(
            //   transitionDuration: Duration(milliseconds: 500),
            //   pageBuilder: (context, animation, secondaryAnimation) =>
            //       LauncherView(),
            // ));
          }),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("App Locker"),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings),
        //     onPressed: () {
        //       setAsDefaultLauncher();
        //     },
        //   ),
        // ],
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

  final ValueNotifier<String> _searchQuery = ValueNotifier('');

  Widget buildAppList(bool locked) {
    return Column(
      children: [
        // Search TextField
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search apps...',
              prefixIcon: Icon(Icons.search, color: Colors.cyan),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color.fromARGB(221, 26, 26, 26),
              hintStyle: TextStyle(color: Colors.grey),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              _searchQuery.value = value;
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.cyan)))
              : ValueListenableBuilder<List<AppInfo>>(
                  valueListenable: _allApps,
                  builder: (context, allApps, _) {
                    return ValueListenableBuilder<Set<String>>(
                      valueListenable: _lockedApps,
                      builder: (context, lockedApps, _) {
                        return ValueListenableBuilder<String>(
                          valueListenable: _searchQuery,
                          builder: (context, searchQuery, _) {
                            List<AppInfo> apps = allApps
                                .where((app) =>
                                    locked ==
                                        lockedApps.contains(app.packageName) &&
                                    app.name
                                        .toLowerCase()
                                        .contains(searchQuery.toLowerCase()))
                                .toList();

                            return ListView.builder(
                              padding:
                                  const EdgeInsets.only(bottom: 10, top: 10),
                              itemCount: apps.length,
                              itemBuilder: (context, index) {
                                final app = apps[index];
                                return FutureBuilder<List<String>?>(
                                  future: Future(() async {
                                    final primaryData = await getPrefStringList(
                                        app.packageName);
                                    if (primaryData != null) {
                                      return primaryData;
                                    }

                                    // If not primary, check if it's a secondary app
                                    for (var lockedApp in lockedApps) {
                                      final mappingData =
                                          await getPrefStringList(
                                              app.packageName);
                                      if (mappingData != null &&
                                          mappingData[1] == app.packageName) {
                                        return [
                                          ...mappingData,
                                          lockedApp
                                        ]; // Include primary package name
                                      }
                                    }
                                    return null;
                                  }),
                                  builder: (context, snapshot) {
                                    bool isPrimary = false;
                                    String? mappedAppName;
                                    bool isHidden = false;

                                    if (snapshot.hasData &&
                                        snapshot.data != null) {
                                      if (snapshot.data != null &&
                                          snapshot.data!.length > 4) {
                                        // This is a secondary app
                                        isPrimary = false;
                                        final primaryPackageName =
                                            snapshot.data![0];
                                        final primaryApp = allApps.firstWhere(
                                          (a) =>
                                              a.packageName ==
                                              primaryPackageName,
                                        );
                                        mappedAppName = primaryApp.name;
                                        isHidden = snapshot.data![2] == 'false';
                                      } else {
                                        // This is a primary app
                                        if (snapshot.data != null &&
                                            snapshot.data!.isNotEmpty) {
                                          isPrimary = true;

                                          final mappedPackageName =
                                              snapshot.data![1];
                                          final mappedApp = allApps.firstWhere(
                                            (a) =>
                                                a.packageName ==
                                                mappedPackageName,
                                          );
                                          mappedAppName = mappedApp.name;
                                          isHidden =
                                              snapshot.data![2] == 'true';
                                        }
                                      }
                                    }

                                    return Card(
                                      color:
                                          const Color.fromARGB(221, 26, 26, 26),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: ListTile(
                                        leading: CachedMemoryImage(
                                          uniqueKey: app.icon.toString(),
                                          bytes: app.icon!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.android,
                                                  size: 40),
                                        ),
                                        title: Text(
                                          app.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: mappedAppName != null
                                            ? Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "Mapped to → ${mappedAppName}",
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isPrimary
                                                          ? Colors.green[300]
                                                          : Colors.blue[300],
                                                    ),
                                                  ),
                                                  Text(
                                                    isHidden
                                                        ? "Hidden (Secondary App)"
                                                        : "Visible (Primary App)",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isHidden
                                                          ? const Color
                                                              .fromARGB(
                                                              255, 240, 78, 78)
                                                          : const Color
                                                              .fromARGB(255,
                                                              105, 255, 113),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : null,
                                        trailing: Icon(
                                            color: locked
                                                ? Colors.white
                                                : selectedAppPackageName
                                                        .isNotEmpty
                                                    ? selectedAppPackageName ==
                                                            app.packageName
                                                        ? Colors.green[400]
                                                        : Colors.white
                                                    : Colors.white,
                                            locked
                                                ? Icons.lock
                                                : selectedAppPackageName
                                                        .isNotEmpty
                                                    ? selectedAppPackageName ==
                                                            app.packageName
                                                        ? Icons
                                                            .check_circle_outline_rounded
                                                        : Icons.lock_open
                                                    : Icons.lock_open),
                                        onLongPress: () {
                                          if (locked) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text(
                                                      "Confirm App unlocking"),
                                                  content: const Text(
                                                      "Are you sure you want to unlock this application?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        FirebaseLogger.logEvent(
                                                            "cancel_btn_are_you_sure_unlocking_application");
                                                        Navigator.of(context)
                                                            .pop(); // Close dialog
                                                      },
                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    233,
                                                                    233,
                                                                    233)),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        FirebaseLogger.logEvent(
                                                            "unlock_app",
                                                            parameters: {
                                                              "selected_package_name":
                                                                  selectedAppPackageName,
                                                            });
                                                        Navigator.of(context)
                                                            .pop();
                                                        if (selectedAppPackageName == "com.whatsapp" ||
                                                            selectedAppPackageName ==
                                                                "com.whatsapp.w4b" ||
                                                            selectedAppPackageName ==
                                                                "com.instagram.android" ||
                                                            selectedAppPackageName ==
                                                                "org.telegram.messenger" ||
                                                            selectedAppPackageName ==
                                                                "com.microsoft.teams") {
                                                          EnablePermissionDialog(
                                                              context,
                                                              app.packageName);
                                                        } else {
                                                          toggleLock(
                                                              app.packageName);
                                                        }
                                                      },
                                                      child: const Text(
                                                        "Confirm",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    255,
                                                                    255,
                                                                    255)),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        },
                                        onTap: () async {
                                          if (locked) {
                                            SecureAppLauncher().launchSecureApp(
                                                app.packageName, locked);
                                            return;
                                          }
                                          if (selectedAppPackageName
                                              .isNotEmpty) {
                                            if (selectedAppPackageName ==
                                                app.packageName) {
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
                                                  title: const Text(
                                                      "Confirm Mapping"),
                                                  content: Text(
                                                      "Are you sure you want to map ${app.name} with $selectedAppName?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        FirebaseLogger.logEvent(
                                                          "lock_app_cancel_btn",
                                                        );
                                                        Navigator.of(context)
                                                            .pop(); // Close dialog
                                                      },
                                                      child: const Text(
                                                        "Cancel",
                                                        style: TextStyle(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    233,
                                                                    233,
                                                                    233)),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        FirebaseLogger.logEvent(
                                                            "lock_app",
                                                            parameters: {
                                                              "primary_app":
                                                                  selectedMapAppPackageName,
                                                              "secondary_app":
                                                                  selectedAppPackageName
                                                            });
                                                        setState(() {
                                                          selectedMapAppPackageName =
                                                              app.packageName;
                                                        });
                                                        Navigator.of(context)
                                                            .pop(); // Close dialog after confirming
                                                        if (selectedAppPackageName == "com.whatsapp" ||
                                                            selectedAppPackageName ==
                                                                "com.whatsapp.w4b" ||
                                                            selectedAppPackageName ==
                                                                "com.instagram.android" ||
                                                            selectedAppPackageName ==
                                                                "org.telegram.messenger" ||
                                                            selectedAppPackageName ==
                                                                "com.microsoft.teams") {
                                                          await notificationPermissionDialog(
                                                              context);
                                                        } else {
                                                          Navigator.of(context)
                                                              .push(
                                                                  MaterialPageRoute(
                                                            builder: (context) =>
                                                                LockAppView(
                                                                    callBack:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        selectedMapAppPackageName =
                                                                            "";
                                                                        selectedAppIcon =
                                                                            null;
                                                                        selectedAppName =
                                                                            "";
                                                                        selectedAppPackageName =
                                                                            "";
                                                                      });
                                                                      fetchApps();
                                                                    },
                                                                    appIconImage:
                                                                        selectedAppIcon,
                                                                    selectedMapAppName:
                                                                        selectedMapAppPackageName,
                                                                    selectedPackageName:
                                                                        selectedAppPackageName,
                                                                    setAppLockPin:
                                                                        true,
                                                                    isPinAlreadySet:
                                                                        true),
                                                          ));
                                                        }
                                                      },
                                                      child: const Text(
                                                        "Confirm",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    255,
                                                                    255,
                                                                    255)),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            setState(() {
                                              selectedAppPackageName =
                                                  app.packageName;
                                              selectedAppIcon = app.icon;
                                              selectedAppName = app.name;
                                            });
                                          }
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
