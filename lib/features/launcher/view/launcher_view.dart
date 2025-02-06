import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class LauncherView extends StatefulWidget {
  const LauncherView({super.key});

  @override
  _LauncherViewState createState() => _LauncherViewState();
}

class _LauncherViewState extends State<LauncherView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<LauncherViewModel>(context, listen: false).loadApps();
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
          app.packageName != "com.gallery.app_lock"
              ? ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Uninstall',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    if (app.packageName != "com.gallery.app_lock") {
                      await launcher.uninstallApp(app);
                    }
                  },
                )
              : const SizedBox(width: 0, height: 0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LauncherViewModel>(
      builder: (context, launcher, child) => WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: launcher.loading
              ? Center(
                  child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Lottie.asset("assets/loading_lottie.json")))
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (page) {},
                          itemCount: launcher.pages.length,
                          itemBuilder: (context, pageIndex) {
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: launcher.pages[pageIndex].items.length,
                              itemBuilder: (context, index) {
                                final app = launcher.pages[pageIndex]
                                    .items[index] as Application;
                                return _buildAppItem(app, launcher);
                              },
                            );
                          },
                        ),
                      ),
                      // if (launcher.pages.length > 1)
                      //   PageIndicator(
                      //     currentPage: _currentPage,
                      //     pageCount: launcher.pages.length,
                      //   ),
                      _buildFooter(launcher),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppItem(Application app, LauncherViewModel launcher) {
    return GestureDetector(
      onTap: () async {
        if (app.packageName == "com.gallery.app_lock") {
          bool pinStatus = await getPrefBool(is_pin_set) ?? false;
          Navigator.of(context).push(PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LockAppView(isPinAlreadySet: pinStatus, callBack: () {}),
          ));
        } else {
          launcher.openAppLockScreen(app.packageName,context);
          
        }
      },
      onLongPress: () => _showAppOptions(context, app, launcher),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (app is ApplicationWithIcon)
            Image.memory(
              app.icon,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            )
          else
            const Icon(Icons.android, size: 50, color: Colors.white),
          const SizedBox(height: 4),
          Text(
            app.appName,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LauncherViewModel launcher) {
    return Container(
      height: 100,
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: launcher.pinnedApps?.length ?? 0,
        itemBuilder: (context, index) {
          final app = launcher.pinnedApps![index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildAppItem(app, launcher),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    Key? key,
    required this.currentPage,
    required this.pageCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          pageCount,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index == currentPage ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
