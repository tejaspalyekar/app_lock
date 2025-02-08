import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermissions(BuildContext context) async {
  // Check for notification policy access
  if (!await Permission.notification.isGranted) {
    await Permission.notification.request();
  }

  // Request notification policy access (DND access)
  if (await Permission.accessNotificationPolicy.status.isDenied) {
    // Show dialog explaining why we need the permission
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permission Required'),
          content: const Text(
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            'Please grant Phone & Call logs permission from App permissions',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text(
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                  'Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                  style: TextStyle(
                      color: Color.fromARGB(255, 184, 184, 184),
                      fontWeight: FontWeight.w500),
                  'Cancel'),
            ),
          ],
        ),
      );
    }
  }
}
