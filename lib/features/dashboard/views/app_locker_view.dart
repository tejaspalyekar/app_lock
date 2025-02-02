import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppLocker extends StatefulWidget {
  @override
  _AppLocker createState() => _AppLocker();
}

class _AppLocker extends State<AppLocker> {
  final ValueNotifier<List<AppInfo>> _allApps = ValueNotifier([]);
  final ValueNotifier<Set<String>> _lockedApps = ValueNotifier({});
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchApps();
  }

  Future<void> fetchApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(false, true);
    _allApps.value = apps;
    setState(() => _loading = false);
  }

  void toggleLock(String packageName) {
    _lockedApps.value = Set.from(_lockedApps.value)..toggle(packageName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("App Locker")),
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
                  return ListView.separated(
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Colors.transparent,
                    ),
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return ListTile(
                        onTap: () => toggleLock(app.packageName),
                        leading: app.icon != null
                            ? Image.memory(app.icon!, width: 40, height: 40)
                            : const Icon(Icons.android, size: 40),
                        title: Text(app.name),
                        trailing: Icon(locked ? Icons.lock : Icons.lock_open),
                      );
                    },
                  );
                },
              );
            },
          );
  }
}

extension ToggleSet<T> on Set<T> {
  void toggle(T value) => contains(value) ? remove(value) : add(value);
}
