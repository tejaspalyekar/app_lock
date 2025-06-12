import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LauncherViewModel extends ChangeNotifier {
  List<LauncherPage> pages = [LauncherPage(apps: []), LauncherPage(apps: [])];
  List<Application>? pinnedApps;
  bool loading = false;
  static const int APPS_PER_PAGE = 24;
  late List<Application> installedApps;
  List<Application> installedApps1 = [];

  // Cache for installed apps
  List<Application>? _cachedApps;
  DateTime? _lastLoadTime;

  // Stream subscription for app events
  StreamSubscription? _appEventSubscription;

  LauncherViewModel(BuildContext context) {
    _initializeAppEvents(context);
  }

  void _initializeAppEvents(BuildContext context) {
    _appEventSubscription =
        DeviceApps.listenToAppsChanges().listen((event) async {
      if (event.event == ApplicationEventType.installed ||
          event.event == ApplicationEventType.updated ||
          event.event == ApplicationEventType.uninstalled) {
        if (event.event == ApplicationEventType.uninstalled) {
          FirebaseLogger.logEvent("listenToAppsChanges",
              parameters: {"event_name": event.event.toString()});
          try {
            List<String>? lockedAppsList =
                await getPrefStringList(locked_app_list) ?? [];
            if (lockedAppsList.contains(event.packageName)) {
              lockedAppsList.remove(event.packageName);
              setPrefStringList(locked_app_list, lockedAppsList);
            }
          } catch (e) {
            log(e.toString());
            FirebaseLogger.logEvent("error_listen_to_app_changes", parameters: {
              "error": e.toString(),
            });
          }
        }
        refreshApps(context);
      }
    });
  }

  Future<void> refreshApps(BuildContext context) async {
    FirebaseLogger.logEvent("refresh_apps");
    _cachedApps = null;
    await loadApps(false, context);
  }

  Future<List<Application>> _getInstalledApps() async {
    FirebaseLogger.logEvent("get_installed_apps");
    if (_cachedApps != null && _lastLoadTime != null) {
      final difference = DateTime.now().difference(_lastLoadTime!);
      return _cachedApps!;
    }

    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
      );

      // Filter out any apps that might cause issues
      final filteredApps = apps.where((app) {
        try {
          // Try accessing properties that might be null
          final hasValidName = app.appName.isNotEmpty;
          final hasValidPackage = app.packageName.isNotEmpty;
          return hasValidName && hasValidPackage;
        } catch (e) {
          log('Error filtering app: ${e.toString()}');
          return false;
        }
      }).toList();

      _cachedApps = filteredApps;
      _lastLoadTime = DateTime.now();
      return filteredApps;
    } catch (e) {
      log('Error getting installed apps: ${e.toString()}');
      FirebaseLogger.logEvent("get_installed_apps_error",
          parameters: {"error": e.toString()});
      return [];
    }
  }

  Future<void> loadApps(
      bool isFromGettingStartedScreen, BuildContext context) async {
    FirebaseLogger.logEvent("load_apps_started");
    try {
      loading = true;

      final prefs = await SharedPreferences.getInstance();
      installedApps = await _getInstalledApps();

      List<String> lockedAppList =
          await getPrefStringList(locked_app_list) ?? [];
      if (lockedAppList.isNotEmpty) {
        List<String> lockedPackages = [];

        for (String package in lockedAppList) {
          List<String> appDetails = await getPrefStringList(package) ?? [];
          if (appDetails.length > 2 && appDetails[2] == "true") {
            lockedPackages.add(package);
          }
        }

        installedApps
            .removeWhere((app) => lockedPackages.contains(app.packageName));
      }
      installedApps.sort((a, b) => a.appName.compareTo(b.appName));
      installedApps1.clear();
      installedApps1.addAll(installedApps);
      // Load pinned apps
      String? storedPinnedApps = await prefs.getString('pinned_apps');
      if (storedPinnedApps != null) {
        List<String> pinnedPackages =
            List<String>.from(json.decode(storedPinnedApps));
        pinnedApps = installedApps
            .where((app) => pinnedPackages.contains(app.packageName))
            .toList();
      } else {
        pinnedApps = [];
      }
      log(pinnedApps.toString());
      installedApps.removeWhere((app) =>
          pinnedApps!.any((pinned) => pinned.packageName == app.packageName));

      _organizeAppsIntoPages(installedApps);
      FirebaseLogger.logEvent("load_apps_finished");
      loading = false;
    } catch (e) {
      FirebaseLogger.logEvent("load_apps_error",
          parameters: {"error": e.toString()});
      log(e.toString());
    }
    log(pinnedApps.toString());
    notifyListeners();
  }

  @override
  void dispose() {
    FirebaseLogger.logEvent("launcher_view_disposed");
    _appEventSubscription?.cancel();
    super.dispose();
  }

  // updatePanel(int page) {
  //   currentPage = page;
  //   notifyListeners();
  // }

  void _organizeAppsIntoPages(List<Application> apps) {
    try {
      pages.clear();
      pages.add(LauncherPage(apps: []));
      pages.add(LauncherPage(apps: []));
      LauncherPage currentPage = LauncherPage(apps: []);

      List<Application> pinnedApps = [];
      Set<String> pinnedCategories = {};

      // Updated priority order and known package names
      List<String> pinOrder = ["phone", "message", "whatsapp", "camera"];
      Map<String, List<String>> categoryMap = {
        "phone": [
          "com.google.android.dialer",
          "com.android.dialer",
          "com.samsung.android.dialer",
          "com.oneplus.dialer",
          "com.miui.dialer"
        ],
        "message": [
          "com.android.messaging",
          "com.samsung.android.messaging",
          "com.google.android.apps.messaging",
          "com.miui.mms"
        ],
        "whatsapp": ["com.whatsapp"],
        "camera": [
          "com.android.camera",
          "com.sec.android.app.camera",
          "com.oppo.camera",
          "org.codeaurora.snapcam"
        ],
      };

      // Step 1: Find and sort pinned apps in required order
      for (var category in pinOrder) {
        for (var app in apps) {
          if (!pinnedCategories.contains(category) &&
              categoryMap[category]!.contains(app.packageName)) {
            pinnedApps.add(app);
            pinnedCategories.add(category);
            break; // Move to next category after finding one app
          }
        }
      }

      // Step 2: Pin the selected apps in order
      for (var pinnedApp in pinnedApps) {
        pinApp(pinnedApp);
      }

      // Step 3: Add remaining apps to pages in A-Z order
      for (var app in apps) {
        if (!pinnedApps.contains(app)) {
          if (currentPage.items.length >= APPS_PER_PAGE) {
            pages.add(currentPage);
            currentPage = LauncherPage(apps: []);
          }
          if (app.packageName != "com.android.traceur") {
            currentPage.items.add(app);
          }
        }
      }

      if (currentPage.items.isNotEmpty) {
        pages.add(currentPage);
      }
    } catch (e) {
      FirebaseLogger.logEvent("organize_apps_error",
          parameters: {"error": e.toString()});
      log(e.toString());
    }
  }

  Future<void> uninstallApp(Application app) async {
    FirebaseLogger.logEvent("uninstall_app", parameters: {"app": app.appName});
    try {
      bool wasUninstalled = await DeviceApps.uninstallApp(app.packageName);
      await Future.delayed(const Duration(seconds: 2));
      Application? checkApp = await DeviceApps.getApp(app.packageName, false);
      if (checkApp == null) {
        if (wasUninstalled) {
          // Remove from pinned apps
          pinnedApps?.removeWhere((a) => a.packageName == app.packageName);

          // Remove from pages
          for (var page in pages) {
            page.items.removeWhere((item) =>
                item is Application && item.packageName == app.packageName);
          }

          // Rebalance pages
          List<Application> allApps = [];
          for (var page in pages) {
            allApps.addAll(page.items.whereType<Application>());
          }
          _organizeAppsIntoPages(allApps);

          notifyListeners();
          _savePinnedApps();
        }
      }
    } catch (e) {
      FirebaseLogger.logEvent("uninstall_app_error",
          parameters: {"app": app.appName, "error": e.toString()});
      log(e.toString());
    }
  }

  Future<void> _savePinnedApps() async {
    FirebaseLogger.logEvent("save_pinned_apps");
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pinned_apps',
        json.encode(pinnedApps?.map((app) => app.packageName).toList() ?? []),
      );
    } catch (e) {
      log(e.toString());
      FirebaseLogger.logEvent("save_pinned_apps_error",
          parameters: {"error": e.toString()});
    }
  }

  void pinApp(Application app) {
    FirebaseLogger.logEvent("pin_app");

    pinnedApps ??= [];
    if (pinnedApps!.length < 4) {
      try {
        if (!pinnedApps!.contains(app)) {
          // Remove from pages
          for (var page in pages) {
            page.items.removeWhere((item) =>
                item is Application && item.packageName == app.packageName);
          }

          pinnedApps!.add(app);
          _savePinnedApps();
          notifyListeners();
        }
      } catch (e) {
        log(e.toString());
        FirebaseLogger.logEvent("pin_app_error",
            parameters: {"app": app.appName, "error": e.toString()});
      }
    }
  }

  void reorderApps(int pageIndex, int fromIndex, int toIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return;
    if (fromIndex < 0 || fromIndex >= pages[pageIndex].items.length) return;
    if (toIndex < 0 || toIndex >= pages[pageIndex].items.length) return;

    final page = pages[pageIndex];
    final item = page.items.removeAt(fromIndex);
    page.items.insert(toIndex, item);

    // Optionally save the new order to persistent storage
    _saveAppOrder(pageIndex);

    notifyListeners();
  }

  Future<void> _saveAppOrder(int pageIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pageApps = pages[pageIndex]
          .items
          .map((app) => (app as Application).packageName)
          .toList();
      await prefs.setStringList('page_${pageIndex}_order', pageApps);
    } catch (e) {
      FirebaseLogger.logEvent("save_app_order_error",
          parameters: {"error": e.toString()});
      log(e.toString());
    }
  }

  void unpinApp(Application app) {
    FirebaseLogger.logEvent("unpin_app");
    try {
      if (pinnedApps?.remove(app) ?? false) {
        // Add back to pages
        if (pages.last.items.length >= APPS_PER_PAGE) {
          pages.add(LauncherPage(apps: [app]));
        } else {
          pages.last.items.add(app);
        }
        _savePinnedApps();
        notifyListeners();
      }
    } catch (e) {
      log(e.toString());
      FirebaseLogger.logEvent("unpin_app_error",
          parameters: {"app": app.appName, "error": e.toString()});
    }
  }

  openAppLockScreen(String packageName, BuildContext context) async {
    FirebaseLogger.logEvent("open_app_lock_screen",
        parameters: {"app": packageName});
    List<String>? lockedAppList =
        await getPrefStringList(locked_app_list) ?? [];

    if (lockedAppList.contains(packageName)) {
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LockAppView(
            isUnLockScreen: true,
            selectedMapAppName: packageName,
            isPinAlreadySet: true,
            callBack: (value) {
              DeviceApps.openApp(packageName);
            }),
      ));
    } else {
      DeviceApps.openApp(packageName);
    }
  }
}

class LauncherPage {
  List<dynamic> items;
  LauncherPage({required List<Application> apps}) : items = apps;
}

class AppFolder {
  String name;
  List<Application> apps;

  AppFolder({required this.name, required this.apps});
}
