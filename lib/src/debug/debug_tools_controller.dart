import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the debug tools: whether they are available in this build or for
/// this user, and whether the floating button is on screen. Available as
/// `Planish.debugTools`.
///
/// ```dart
/// // After sign-in, for testers only, in any build:
/// if (user.isTester) await Planish.debugTools.allow(true, remember: true);
/// ```
class DebugToolsController extends ChangeNotifier {
  static const String _visibleKey = 'planish.debug_button_visible';
  static const String _allowedKey = 'planish.debug_tools_allowed';

  bool _visible = false;
  bool _remember = false;
  bool _byDefault = false;
  bool _allowed = false;

  /// Whether the floating button is on screen.
  bool get isVisible => isAvailable && _visible;

  /// Whether the debug tools can be used: on by default in this build
  /// (`DebugToolsConfig.enabled`), or allowed at run time with [allow].
  bool get isAvailable => _byDefault || _allowed;

  /// Restores the saved state. Called by `Planish.init`.
  Future<void> load({required bool enabled, required bool remember}) async {
    _byDefault = enabled;
    _remember = remember;
    try {
      final prefs = await SharedPreferences.getInstance();
      _allowed = prefs.getBool(_allowedKey) ?? false;
      if (remember) {
        _visible = prefs.getBool(_visibleKey) ?? false;
      }
    } on Object {
      // No storage: defaults stand.
    }
    notifyListeners();
  }

  /// Makes the debug tools available, or not, whatever the build: a shake
  /// then shows the floating button, as in a debug build. Call it once the
  /// app knows who is signed in, for testers or for yourself. With
  /// [remember], the choice survives restarts on this device until
  /// `allow(false)`. It cannot take the tools away from a build where
  /// `DebugToolsConfig.enabled` is true.
  Future<void> allow(bool allowed, {bool remember = false}) async {
    final changed = _allowed != allowed;
    _allowed = allowed;
    if (!allowed) {
      _visible = false;
    }
    if (changed) {
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      if (allowed && remember) {
        await prefs.setBool(_allowedKey, true);
      } else {
        await prefs.remove(_allowedKey);
      }
    } on Object {
      // No storage: the grant lasts for this session.
    }
  }

  /// Forgets every state. Called by `Planish.reset`, for tests.
  void reset() {
    _visible = false;
    _remember = false;
    _byDefault = false;
    _allowed = false;
  }

  /// Shows the button.
  void show() => _set(true);

  /// Hides the button.
  void hide() => _set(false);

  /// Toggles the button.
  void toggle() => _set(!_visible);

  void _set(bool value) {
    if (_visible == value) {
      return;
    }
    _visible = value;
    notifyListeners();
    if (_remember) {
      SharedPreferences.getInstance()
          .then((SharedPreferences p) => p.setBool(_visibleKey, value))
          .ignore();
    }
  }
}
