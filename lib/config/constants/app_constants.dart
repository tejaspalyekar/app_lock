import 'package:flutter/material.dart';

Color commonWhiteColor = Color.fromARGB(255, 212, 212, 212);
String firebaseCollectionName = 'products';

int pinCodeLength = 6;

//key value for shared preferences

String app_lock_pin = "APP_LOCK_PIN";
String is_pin_set = "IS_PIN_SET";
String app_uninstall_pin = "APP_UNINSTALL_PIN";
String locked_app_list = "LOCKED_APP_LIST";
String app_lock = "APP_LOCK";
// for locked package name list format packageName :[pin,mappedAppPackageName,true/false(hidden)]