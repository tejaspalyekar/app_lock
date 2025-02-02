import 'package:app_lock/features/lock_app/views/lock_app_view.dart';
import 'package:flutter/material.dart';

Map<String, Widget Function(BuildContext)> appRoutes = {
  '/': (context) => LockAppView(),
};
