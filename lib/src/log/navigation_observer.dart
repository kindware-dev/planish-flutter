import 'package:flutter/widgets.dart';
import 'package:planish/src/log/log.dart';

/// Logs screen changes and remembers the current one for reports.
///
/// ```dart
/// MaterialApp(navigatorObservers: [Planish.navigationObserver], ...)
/// GoRouter(observers: [Planish.navigationObserver], ...)
/// ```
///
/// Only page routes with a name are tracked, so dialogs, menus and sheets
/// stay out of the logs.
class LoggingNavigatorObserver extends NavigatorObserver {
  static const String tag = 'nav';

  String? _current;

  /// Name of the route on top, or null before the first named push.
  String? get currentRoute => _current;

  String? _name(Route<dynamic>? route) {
    if (route is! PageRoute) {
      return null;
    }
    final name = route.settings.name;
    return name == null || name.isEmpty ? null : name;
  }

  void _arrived(String? name, String verb) {
    if (name == null) {
      return;
    }
    _current = name;
    Log.info('$verb $name', tag: tag);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _arrived(_name(route), 'Opened');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_name(route) != null) {
      _arrived(_name(previousRoute), 'Back to');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _arrived(_name(newRoute), 'Replaced with');

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_name(route) != null) {
      _arrived(_name(previousRoute), 'Back to');
    }
  }
}
