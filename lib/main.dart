import 'package:app_lock/config/route.dart';
import 'package:app_lock/config/theme.dart';
import 'package:app_lock/features/lock_app/view_model/upload_new_item_view_model.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LockAppViewModel(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'App Lock',
        theme: appThemeData,
        routes: appRoutes,
        initialRoute: '/',
      ),
    );
  }
}
