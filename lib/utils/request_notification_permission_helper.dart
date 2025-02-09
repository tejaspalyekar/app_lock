import 'package:app_lock/utils/FirebaseLogger.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestNotificationPermissions(BuildContext context) async {
  if (!await Permission.notification.isGranted) {
    await Permission.notification.request();
  }

  if (await Permission.accessNotificationPolicy.status.isDenied) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            'Permission Required',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Please allow restricted settings to manage notifications effectively for hidden apps.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseLogger.logEvent("Restricted permissions not allowed");
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                FirebaseLogger.logEvent("Open restricted permissions settings");
                Navigator.pop(context);
                openAppSettings();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.cyan.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
