import 'package:logger/logger.dart';

class CustomLog {
  var logger = Logger(
    filter: null, // Use the default LogFilter (-> only log in debug mode)
    printer: PrettyPrinter(), // Use the PrettyPrinter to format and print log
    output: null, // Use the default LogOutput (-> send everything to console)
  );

  errorLog(String msg) {
    logger.e(msg);
  }

  debugLog(String msg) {
    logger.d(msg);
  }

  infoLog(String msg) {
    logger.i(msg);
  }
}
