import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class FirebaseLogger {
  static final FirebaseCrashlytics crashlytics = FirebaseCrashlytics.instance;
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  /// log event
  static void logEvent(String msg, {Map<String, Object>? parameters}) async {
    await FirebaseAnalytics.instance
        .logEvent(name: msg, parameters: parameters);
  }

  /// Logs a simple message
  static void log(String message) {
    crashlytics.log(message);
  }

  /// Logs a message with attributes
  static void logWithAttributes(
      String message, Map<String, dynamic> attributes) {
    String attributesString =
        attributes.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    crashlytics.log('$message - Attributes: $attributesString');
  }

  /// Logs a formatted message
  static void logFormatted(String format, List<dynamic> args) {
    String formattedMessage = format;
    for (var arg in args) {
      formattedMessage = formattedMessage.replaceFirst('%s', arg.toString());
    }
    crashlytics.log(formattedMessage);
  }
}
