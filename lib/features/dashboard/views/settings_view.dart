import 'package:app_lock/config/app_navigator.dart';
import 'package:flutter/material.dart';


class SettingsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> settingsOptions = [
    {'icon': Icons.video_library, 'title': 'Video Editor'},
    {'icon': Icons.grid_on, 'title': 'Collage'},
    {'icon': Icons.content_cut, 'title': 'Clip'},
    {'icon': Icons.delete, 'title': 'Free Up Space'},
    {'icon': Icons.settings, 'title': 'Settings'},
    {'icon': Icons.help_outline, 'title': 'Help & Feedback'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        itemCount: settingsOptions.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(settingsOptions[index]['icon'],
                color: const Color.fromARGB(255, 255, 255, 255)),
            title: Text(
              settingsOptions[index]['title'],
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () {
              if (index == 4) {
                pushScreen(context, '/homeScreen');
              }
            },
          );
        },
      ),
    );
  }
}
