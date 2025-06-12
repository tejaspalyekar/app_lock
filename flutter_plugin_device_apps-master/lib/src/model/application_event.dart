enum ApplicationEventType {
  /// Application is installed
  installed,

  /// Application is updated (eg: from version 1 to 2)
  updated,

  /// Application is uninstalled from the device
  uninstalled,

  /// Application is enabled by the user
  enabled,

  /// Application is disabled by the user (but still installed)
  disabled,
}

/// Event triggered when an application is installed, updated, uninstalled, enabled or disabled
class ApplicationEvent {
  /// Type of the event
  final ApplicationEventType type;

  /// Package name of the application
  final String packageName;

  ApplicationEvent._(Map<dynamic, dynamic> map)
      : type = ApplicationEventType.values[map['type'] as int],
        packageName = map['package_name'] as String;

  @override
  String toString() {
    return 'ApplicationEvent{type: $type, packageName: $packageName}';
  }
}
