import 'dart:async';
import 'dart:convert';
import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LauncherViewModel extends ChangeNotifier {
  List<LauncherPage> pages = [LauncherPage(apps: [])];
  List<Application>? pinnedApps;
  int currentPage = 0;
  bool loading = false;
  static const int APPS_PER_PAGE = 20;

  // Cache for installed apps
  List<Application>? _cachedApps;
  DateTime? _lastLoadTime;

  // Stream subscription for app events
  StreamSubscription? _appEventSubscription;

  LauncherViewModel() {
    _initializeAppEvents();
  }

  void _initializeAppEvents() {
    _appEventSubscription = DeviceApps.listenToAppsChanges().listen((event) {
      if (event.event == ApplicationEventType.installed ||
          event.event == ApplicationEventType.updated ||
          event.event == ApplicationEventType.uninstalled) {
        refreshApps();
      }
    });
  }

  Future<void> refreshApps() async {
    _cachedApps = null;
    await loadApps();
  }

  Future<List<Application>> _getInstalledApps() async {
    if (_cachedApps != null && _lastLoadTime != null) {
      final difference = DateTime.now().difference(_lastLoadTime!);
      return _cachedApps!;
    }

    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );

    _cachedApps = apps;
    _lastLoadTime = DateTime.now();
    return apps;
  }

  Future<void> loadApps() async {
    loading = true;
    final prefs = await SharedPreferences.getInstance();
    final installedApps = await _getInstalledApps();
    List<String> lockedAppList = await getPrefStringList(locked_app_list) ?? [];
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

    // Load pinned apps
    String? storedPinnedApps = prefs.getString('pinned_apps');
    if (storedPinnedApps != null) {
      List<String> pinnedPackages =
          List<String>.from(json.decode(storedPinnedApps));
      pinnedApps = installedApps
          .where((app) => pinnedPackages.contains(app.packageName))
          .toList();
    } else {
      pinnedApps = [];
    }

    installedApps.removeWhere((app) =>
        pinnedApps!.any((pinned) => pinned.packageName == app.packageName));

    _organizeAppsIntoPages(installedApps);
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _appEventSubscription?.cancel();
    super.dispose();
  }

  updatePanel(int page) {
    currentPage = page;
    notifyListeners();
  }

  void _organizeAppsIntoPages(List<Application> apps) {
    pages.clear();
    LauncherPage currentPage = LauncherPage(apps: []);

    for (var app in apps) {
      if (currentPage.items.length >= APPS_PER_PAGE) {
        pages.add(currentPage);
        currentPage = LauncherPage(apps: []);
      }
      currentPage.items.add(app);
    }

    if (currentPage.items.isNotEmpty) {
      pages.add(currentPage);
    }
  }

  Future<void> uninstallApp(Application app) async {
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
  }

  Future<void> _savePinnedApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'pinned_apps',
      json.encode(pinnedApps?.map((app) => app.packageName).toList() ?? []),
    );
  }

  void pinApp(Application app) {
    pinnedApps ??= [];
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
  }

  void unpinApp(Application app) {
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
  }

  openAppLockScreen(String packageName, BuildContext context) async {
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
