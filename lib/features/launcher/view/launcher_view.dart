import 'dart:async';

import 'package:app_lock/config/constants/app_constants.dart';
import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class LauncherView extends StatefulWidget {
  LauncherView({super.key, this.fromGetStartedScreen});

  bool? fromGetStartedScreen;

  @override
  _LauncherViewState createState() => _LauncherViewState();
}

class _LauncherViewState extends State<LauncherView> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    pushLockScreen();
  }

  pushLockScreen() async {
    if (widget.fromGetStartedScreen ?? false) {
      await setPrefBool("isFirstTime", false);

      bool pinStatus = await getPrefBool(is_pin_set) ?? false;
      Navigator.pop(context);
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LockAppView(
            uninstallApp: pinStatus,
            isPinAlreadySet: pinStatus,
            callBack: () {}),
      ));
    }

    Provider.of<LauncherViewModel>(context, listen: false)
        .loadApps(widget.fromGetStartedScreen ?? false, context);
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
          launcher.openAppLockScreen(app.packageName, context);
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




//commented code
// import 'package:app_lock/config/constants/app_constants.dart';
// import 'package:app_lock/data/shared_preference/local_data_shared_prefs.dart';
// import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
// import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
// import 'package:app_lock/utils/FirebaseLogger.dart';
// import 'package:flutter/material.dart';
// import 'package:device_apps/device_apps.dart';
// import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';

// // ignore: must_be_immutable
// class LauncherView extends StatefulWidget {
//   LauncherView({super.key, this.fromGetStartedScreen});

//   bool? fromGetStartedScreen;

//   @override
//   _LauncherViewState createState() => _LauncherViewState();
// }

// class _LauncherViewState extends State<LauncherView> {
//   final PageController _pageController = PageController();
//   final Map<int, GlobalKey> _gridKeys = {};
//   int? _draggedIndex;
//   int? _targetIndex;
//   @override
//   void initState() {
//     super.initState();
//     pushLockScreen();
//   }

//   GlobalKey _getGridKey(int pageIndex) {
//     return _gridKeys.putIfAbsent(pageIndex, () => GlobalKey());
//   }

//   pushLockScreen() async {
//     FirebaseLogger.logEvent("push_lock_screen_first_time");
//     if (widget.fromGetStartedScreen ?? false) {
//       await setPrefBool("isFirstTime", false);

//       bool pinStatus = await getPrefBool(is_pin_set) ?? false;
//       Navigator.pop(context);
//       Navigator.of(context).push(PageRouteBuilder(
//         pageBuilder: (context, animation, secondaryAnimation) => LockAppView(
//             uninstallApp: pinStatus,
//             isPinAlreadySet: pinStatus,
//             callBack: () {}),
//       ));
//     }

//     Provider.of<LauncherViewModel>(context, listen: false)
//         .loadApps(widget.fromGetStartedScreen ?? false, context);
//   }
//   Size _getItemSize(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final itemWidth = (screenWidth - 64) / 4;
//     return Size(itemWidth, itemWidth * 1.25);
//   }

//   int _getTargetIndex(Offset localPosition, Size itemSize) {
//     final row = ((localPosition.dy - 16) / (itemSize.height + 16)).floor();
//     final col = ((localPosition.dx - 16) / (itemSize.width + 16)).floor();
//     return (row * 4) + col;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<LauncherViewModel>(
//       builder: (context, launcher, child) => WillPopScope(
//         onWillPop: () async {
//           FirebaseLogger.logEvent("launcher_will_pop_called");
//           return false;
//         },
//         child: Scaffold(
//           backgroundColor: Colors.transparent,
//           body: launcher.loading
//               ? Center(
//                   child: SizedBox(
//                     width: 200,
//                     height: 200,
//                     child: Lottie.asset("assets/loading_lottie.json"),
//                   ),
//                 )
//               : SafeArea(
//                   child: Column(
//                     children: [
//                       Expanded(
//                         child: PageView.builder(
//                           controller: _pageController,
//                           onPageChanged: (page) {},
//                           itemCount: launcher.pages.length,
//                           itemBuilder: (context, pageIndex) {
//                             return GridView.builder(
//                               key: _getGridKey(pageIndex),
//                               padding: const EdgeInsets.all(16),
//                               gridDelegate:
//                                   const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 4,
//                                 childAspectRatio: 0.8,
//                                 crossAxisSpacing: 16,
//                                 mainAxisSpacing: 16,
//                               ),
//                               itemCount: launcher.pages[pageIndex].items.length,
//                               itemBuilder: (context, index) {
//                                 final app = launcher.pages[pageIndex]
//                                     .items[index] as Application;
//                                 return DraggableAppItem(
//                                   key: ValueKey('${app.packageName}_$index'),
//                                   app: app,
//                                   index: index,
//                                   pageIndex: pageIndex,
//                                   isDragged: _draggedIndex == index,
//                                   isTarget: _targetIndex == index,
//                                   onDragStarted: () =>
//                                       setState(() => _draggedIndex = index),
//                                   onDragUpdate: (details) {
//                                     final currentGridKey =
//                                         _getGridKey(pageIndex);
//                                     final RenderBox? grid = currentGridKey
//                                         .currentContext
//                                         ?.findRenderObject() as RenderBox?;
//                                     if (grid != null) {
//                                       final localPosition = grid.globalToLocal(
//                                           details.globalPosition);
//                                       final itemSize = _getItemSize(context);
//                                       final newTarget = _getTargetIndex(
//                                           localPosition, itemSize);

//                                       if (newTarget >= 0 &&
//                                           newTarget <
//                                               launcher.pages[pageIndex].items
//                                                   .length &&
//                                           newTarget != _targetIndex) {
//                                         setState(
//                                             () => _targetIndex = newTarget);
//                                       }
//                                     }
//                                   },
//                                   onDragEnd: (details) {
//                                     if (_targetIndex != null &&
//                                         _draggedIndex != null) {
//                                       launcher.reorderApps(pageIndex,
//                                           _draggedIndex!, _targetIndex!);
//                                     }
//                                     setState(() {
//                                       _draggedIndex = null;
//                                       _targetIndex = null;
//                                     });
//                                   },
//                                   launcher: launcher,
//                                 );
//                               },
//                             );
//                           },
//                         ),
//                       ),
//                       _buildFooter(launcher),
//                     ],
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppItem(Application app, LauncherViewModel launcher) {
//     return GestureDetector(
//       onTap: () async {
//         if (app.packageName == "com.gallery.app_lock") {
//           bool pinStatus = await getPrefBool(is_pin_set) ?? false;
//           Navigator.of(context).push(PageRouteBuilder(
//             pageBuilder: (context, animation, secondaryAnimation) =>
//                 LockAppView(isPinAlreadySet: pinStatus, callBack: () {}),
//           ));
//         } else {
//           launcher.openAppLockScreen(app.packageName, context);
//         }
//       },
//       // onDoubleTap: () => _showAppOptions(context, app, launcher),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           if (app is ApplicationWithIcon)
//             Image.memory(
//               app.icon,
//               width: 50,
//               height: 50,
//               fit: BoxFit.contain,
//             )
//           else
//             const Icon(Icons.android, size: 50, color: Colors.white),
//           const SizedBox(height: 4),
//           Text(
//             app.appName,
//             style: const TextStyle(color: Colors.white, fontSize: 12),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFooter(LauncherViewModel launcher) {
//     return Container(
//       height: 100,
//       color: Colors.transparent,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         itemCount: launcher.pinnedApps?.length ?? 0,
//         itemBuilder: (context, index) {
//           final app = launcher.pinnedApps![index];
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: _buildAppItem(app, launcher),
//           );
//         },
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     _gridKeys.clear();
//     super.dispose();
//   }
// }

// class DraggableAppItem extends StatelessWidget {
//   final Application app;
//   final int index;
//   final int pageIndex;
//   final bool isDragged;
//   final bool isTarget;
//   final VoidCallback onDragStarted;
//   final Function(DragUpdateDetails) onDragUpdate;
//   final Function(DraggableDetails) onDragEnd;
//   final LauncherViewModel launcher;

//   const DraggableAppItem({
//     Key? key,
//     required this.app,
//     required this.index,
//     required this.pageIndex,
//     required this.isDragged,
//     required this.isTarget,
//     required this.onDragStarted,
//     required this.onDragUpdate,
//     required this.onDragEnd,
//     required this.launcher,
//   }) : super(key: key);

//   void _showAppOptions(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color.fromARGB(160, 44, 44, 44),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Wrap(
//         children: [
//           app.packageName != "com.gallery.app_lock"
//               ? ListTile(
//                   leading: const Icon(Icons.settings, color: Colors.white),
//                   title: const Text('App Settings',
//                       style: TextStyle(color: Colors.white)),
//                   onTap: () {
//                     Navigator.pop(context);
//                     DeviceApps.openAppSettings(app.packageName);
//                   },
//                 )
//               : const SizedBox(
//                   height: 0,
//                   width: 0,
//                 ),
//           ListTile(
//             leading: const Icon(Icons.push_pin, color: Colors.white),
//             title: Text(
//               launcher.pinnedApps?.contains(app) == true
//                   ? 'Unpin'
//                   : 'Pin to Footer',
//               style: const TextStyle(color: Colors.white),
//             ),
//             onTap: () {
//               Navigator.pop(context);
//               if (launcher.pinnedApps?.contains(app) == true) {
//                 launcher.unpinApp(app);
//               } else {
//                 launcher.pinApp(app);
//               }
//             },
//           ),
//           ListTile(
//             leading: const Icon(Icons.delete, color: Colors.red),
//             title: const Text('Uninstall', style: TextStyle(color: Colors.red)),
//             onTap: () async {
//               FirebaseLogger.logEvent("uninstall_app_launcher_screen");
//               if (app.packageName == "com.gallery.app_lock") {
//                 FirebaseLogger.logEvent("unlock_to_uninstall");
//                 bool pinStatus = await getPrefBool(is_pin_set) ?? false;
//                 Navigator.pop(context);
//                 Navigator.of(context).push(PageRouteBuilder(
//                   pageBuilder: (context, animation, secondaryAnimation) =>
//                       LockAppView(
//                           uninstallApp: pinStatus,
//                           isPinAlreadySet: pinStatus,
//                           callBack: () {}),
//                 ));
//               } else {
//                 Navigator.pop(context);
//                 if (app.packageName != "com.gallery.app_lock") {
//                   await launcher.uninstallApp(app);
//                 }
//               }
//             },
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       //onLongPress: () => _showAppOptions(context),
//       child: LongPressDraggable<Map<String, dynamic>>(
//         delay: const Duration(milliseconds: 500), // Add delay for drag
//         data: {
//           'app': app,
//           'index': index,
//           'pageIndex': pageIndex,
//         },
//         onDragStarted: onDragStarted,
//         onDragUpdate: onDragUpdate,
//         onDragEnd: (f) {
//           onDragEnd(f);
//           _showAppOptions(context);
//         },
//         feedback: Material(
//           color: Colors.transparent,
//           child: Opacity(
//             opacity: 0.7,
//             child: SizedBox(
//               width: 80,
//               height: 100,
//               child: _buildAppContent(),
//             ),
//           ),
//         ),
//         childWhenDragging: Opacity(
//           opacity: 0.3,
//           child: _buildAppContent(),
//         ),
//         child: GestureDetector(
//           onTap: () async {
//             if (!isDragged) {
//               if (app.packageName == "com.gallery.app_lock") {
//                 bool pinStatus = await getPrefBool(is_pin_set) ?? false;
//                 Navigator.of(context).push(PageRouteBuilder(
//                   pageBuilder: (context, animation, secondaryAnimation) =>
//                       LockAppView(isPinAlreadySet: pinStatus, callBack: () {}),
//                 ));
//               } else {
//                 launcher.openAppLockScreen(app.packageName, context);
//               }
//             }
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border:
//                   isTarget ? Border.all(color: Colors.blue, width: 2) : null,
//             ),
//             transform: isTarget
//                 ? (Matrix4.identity()..scale(1.1))
//                 : Matrix4.identity(),
//             child: _buildAppContent(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppContent() {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         if (app is ApplicationWithIcon)
//           Image.memory(
//             (app as ApplicationWithIcon).icon,
//             width: 50,
//             height: 50,
//             fit: BoxFit.contain,
//           )
//         else
//           const Icon(Icons.android, size: 50, color: Colors.white),
//         const SizedBox(height: 4),
//         Text(
//           app.appName,
//           style: const TextStyle(color: Colors.white, fontSize: 12),
//           textAlign: TextAlign.center,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ],
//     );
//   }
// }

// class PageIndicator extends StatelessWidget {
//   final int currentPage;
//   final int pageCount;

//   const PageIndicator({
//     Key? key,
//     required this.currentPage,
//     required this.pageCount,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: List.generate(
//           pageCount,
//           (index) => Container(
//             width: 8,
//             height: 8,
//             margin: const EdgeInsets.symmetric(horizontal: 4),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: index == currentPage ? Colors.white : Colors.grey,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
