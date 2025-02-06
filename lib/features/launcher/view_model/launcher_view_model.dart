import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

class LauncherViewModel extends ChangeNotifier {
  List<Application>? apps;

  Future<void> loadApps() async {
    List<Application> installedApps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
      onlyAppsWithLaunchIntent: true,
    );

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

    apps = installedApps;
    notifyListeners();
  }

  removeHiddenApp(String packageName) {
    apps!.removeWhere((element) => element.packageName == packageName);
    notifyListeners();
  }
}
