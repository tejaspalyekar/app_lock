import 'dart:developer';

import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view_model/launcher_index_view_model.dart';
import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vs_scrollbar/vs_scrollbar.dart';

class VerticalAppList extends StatefulWidget {
  const VerticalAppList({Key? key}) : super(key: key);

  @override
  State<VerticalAppList> createState() => _VerticalAppListState();
}

class _VerticalAppListState extends State<VerticalAppList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(
      () {
        log("${_scrollController.offset} ");
        if (_scrollController.offset == 0.0) {
          Navigator.of(context).pop();
        }
      },
    );
    // Listen to search text changes
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(209, 0, 0, 0),
      body: Consumer<LauncherViewModel>(
        builder: (context, launcher, child) {
          // Filter apps based on search query
          final filteredApps = _searchQuery.isEmpty
              ? launcher.installedApps1
              : launcher.installedApps1
                  .where(
                      (app) => app.appName.toLowerCase().contains(_searchQuery))
                  .toList();

          return Column(
            children: [
              // Search bar at the top
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    fillColor: const Color.fromARGB(232, 51, 51, 51),
                    filled: true,
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white),
                            onPressed: () {
                              _searchController.clear();
                              _searchFocusNode.unfocus();
                            },
                          )
                        : null,
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(width: 0),
                        borderRadius: BorderRadius.circular(35)),
                    disabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(width: 0),
                        borderRadius: BorderRadius.circular(35)),
                    border: OutlineInputBorder(
                        borderSide: const BorderSide(width: 0),
                        borderRadius: BorderRadius.circular(35)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Apps grid with original gesture detection
              Expanded(
                child: VsScrollbar(
                  controller: _scrollController,
                  showTrackOnHover: true,
                  scrollbarFadeDuration: const Duration(milliseconds: 500),
                  scrollbarTimeToFade: const Duration(milliseconds: 800),
                  style: const VsScrollbarStyle(
                    hoverThickness: 10.0,
                    radius: Radius.circular(10),
                    thickness: 8.0,
                    color: Color.fromARGB(255, 163, 163, 163),
                  ),
                  child: GestureDetector(
                    // Keeping your original gesture implementation
                    // onVerticalDragEnd: (details) {
                    //   final launcherViewModel =
                    //       Provider.of<LauncherIndexViewModel>(context,
                    //           listen: false);
                    //   launcherViewModel.downDragEndValue =
                    //       details.localPosition.distance;
                    //   log(launcherViewModel.isDownDragEnabled.toString());

                    //   if (launcherViewModel.isDownDragEnabled) {
                    //     Navigator.of(context).pop();
                    //   }
                    // },
                    // onVerticalDragStart: (details) =>
                    //     Provider.of<LauncherIndexViewModel>(context,
                    //                 listen: false)
                    //             .downDragStartValue =
                    //         details.localPosition.distance,
                    child: GridView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = filteredApps[index];
                        return _buildAppItem(app, launcher, context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppItem(
      Application app, LauncherViewModel launcher, BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (app.packageName == "com.gallery.app_lock") {
          bool pinStatus = await getPrefBool(is_pin_set) ?? false;
          Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LockAppView(isPinAlreadySet: pinStatus, callBack: () {}),
          ));
        } else {
          launcher.openAppLockScreen(app.packageName, context);
        }
      },
      onLongPress: () => _showAppOptions(context, app, launcher),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (app is ApplicationWithIcon)
            ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CachedMemoryImage(
                  uniqueKey: app.icon.toString(),
                  bytes: app.icon,
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: MediaQuery.of(context).size.width * 0.15,
                  fit: BoxFit.contain,
                ))
          else
            const Icon(Icons.android, size: 50, color: Colors.white),
          const SizedBox(height: 4),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Text(
              app.appName,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  void _showAppOptions(
      BuildContext context, Application app, LauncherViewModel launcher) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(160, 44, 44, 44),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Wrap(
        children: [
          app.packageName != "com.gallery.app_lock"
              ? ListTile(
                  leading: const Icon(Icons.settings, color: Colors.white),
                  title: const Text('App Settings',
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    DeviceApps.openAppSettings(app.packageName);
                  },
                )
              : const SizedBox(
                  height: 0,
                  width: 0,
                ),
          ListTile(
            leading: const Icon(Icons.push_pin, color: Colors.white),
            title: Text(
              launcher.pinnedApps?.contains(app) == true
                  ? 'Unpin'
                  : 'Pin to Footer',
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              if (launcher.pinnedApps?.contains(app) == true) {
                launcher.unpinApp(app);
              } else {
                launcher.pinApp(app);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Uninstall', style: TextStyle(color: Colors.red)),
            onTap: () async {
              if (app.packageName == "com.gallery.app_lock") {
                bool pinStatus = await getPrefBool(is_pin_set) ?? false;
                Navigator.pop(context);
                Navigator.of(context).push(PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LockAppView(
                          uninstallApp: pinStatus,
                          isPinAlreadySet: pinStatus,
                          callBack: () {}),
                ));
              } else {
                Navigator.pop(context);
                if (app.packageName != "com.gallery.app_lock") {
                  await launcher.uninstallApp(app);
                }
              }
            },
          )
        ],
      ),
    );
  }
}
