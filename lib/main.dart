import 'package:app_lock/config/route.dart';
import 'package:app_lock/config/theme.dart';
import 'package:app_lock/features/dashboard/view_models/gallery_view_model.dart';
import 'package:app_lock/features/dashboard/view_models/app_locker_view_model.dart';
import 'package:app_lock/features/launcher/view_model/launcher_view_model.dart';
import 'package:app_lock/features/lock_app/view_models/lock_app_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.inactive) {
  //     // Delay slightly to prevent Android from overriding it
  //     Future.delayed(const Duration(milliseconds: 100), () {
  //       SystemNavigator.pop(); // Forces the app to reopen
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LockAppViewModel()),
        ChangeNotifierProvider(create: (context) => HomeViewModel()),
        ChangeNotifierProvider(create: (context) => GalleryViewModel()),
        ChangeNotifierProvider(create: (context) => LauncherViewModel(context)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Lock',
        theme: appThemeData,
        routes: appRoutes,
        initialRoute: '/',
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          );
        },
      ),
    );
  }
}
