import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

//set shared preferences
setPrefInt(String key, int value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt(key, value);
}

setPrefDouble(String key, double value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setDouble(key, value);
}

setPrefString(String key, String value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, value);
}

setPrefBool(String key, bool value) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool(key, value);
}

//get shared preference
getPrefInt(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt(key);
}

getPrefDouble(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getDouble(key);
}

getPrefString(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

setPrefStringList(String key, List<String> value) async {
  final String jsonString = jsonEncode(value);
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setString(key, jsonString);
}

Future<List<String>> getPrefStringList(String key) async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error decoding JSON: $e. Resetting preference.');
      await prefs.remove(key); // Remove the corrupted data
      return [];
    }
  } catch (e) {
    print('Error reading preference list: $e');
    return [];
  }
}

Future<bool?> getPrefBool(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool(key);
}

removePrefData(String key) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.remove(key);
}
