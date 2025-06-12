import 'dart:async';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';

class AppsEventsScreen extends StatefulWidget {
  const AppsEventsScreen({Key? key}) : super(key: key);

  @override
  _AppsEventsScreenState createState() => _AppsEventsScreenState();
}

class _AppsEventsScreenState extends State<AppsEventsScreen> {
  final List<ApplicationEvent> _events = <ApplicationEvent>[];
  StreamSubscription<ApplicationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _setupSubscription();
  }

  void _setupSubscription() {
    final Stream<ApplicationEvent> stream =
        DeviceApps.listenToAppsChanges().cast<ApplicationEvent>();
    _subscription = stream.listen(
      (ApplicationEvent event) {
        if (mounted) {
          setState(() {
            _events.add(event);
          });
        }
      },
      onError: (Object error) {
        debugPrint('Error listening to app changes: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications events'),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Visibility(
            visible: _events.isNotEmpty,
            child: _EventsList(events: _events),
          ),
          Visibility(
            visible: _events.isEmpty,
            child: const _EmptyList(),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class _EventsList extends StatelessWidget {
  final Iterable<ApplicationEvent> _events;

  _EventsList({required List<ApplicationEvent> events, Key? key})
      : _events = events.reversed,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int position) {
          return KeyedSubtree(
            key: Key('$position'),
            child: _AppEventItem(event: _events.elementAt(position)),
          );
        },
        itemCount: _events.length,
      ),
    );
  }
}

class _AppEventItem extends StatelessWidget {
  final ApplicationEvent event;

  const _AppEventItem({required this.event, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(event.packageName),
          subtitle: _AppEventItemType(type: event.type),
          leading: Text(timeString),
        ),
        const Divider()
      ],
    );
  }
}

class _AppEventItemType extends StatelessWidget {
  final ApplicationEventType type;

  const _AppEventItemType({required this.type, Key? key}) : super(key: key);

  String _getEventTypeName() {
    switch (type) {
      case ApplicationEventType.installed:
        return 'Installed';
      case ApplicationEventType.updated:
        return 'Updated';
      case ApplicationEventType.uninstalled:
        return 'Uninstalled';
      case ApplicationEventType.enabled:
        return 'Enabled';
      case ApplicationEventType.disabled:
        return 'Disabled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_getEventTypeName());
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No event yet!'));
  }
}
