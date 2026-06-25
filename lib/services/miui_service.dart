import 'dart:io';

import 'package:flutter/services.dart';

/// Detects MIUI/HyperOS and attempts to open manufacturer-specific settings
/// screens for autostart, battery optimization, and recents lock.
class MiuiService {
  static const _channel = MethodChannel('noti_sim/miui');
  static bool? _isMiui;

  static Future<bool> isMiui() async {
    if (_isMiui != null) return _isMiui!;
    if (!Platform.isAndroid) {
      _isMiui = false;
      return false;
    }
    try {
      // Detection runs natively via Build.MANUFACTURER / Build.FINGERPRINT.
      _isMiui = await _channel.invokeMethod<bool>('isMiui') ?? false;
    } catch (_) {
      _isMiui = false;
    }
    return _isMiui!;
  }

  /// Attempts to open the MIUI Autostart settings screen.
  static Future<bool> openAutostart() async {
    try {
      return await _channel.invokeMethod<bool>(
            'openIntent',
            {
              'action': 'miui.intent.action.OP_AUTO_START',
              'package': 'com.miui.securitycenter',
            },
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Attempts to open Battery optimization settings for this app.
  static Future<bool> openBatteryOptimization() async {
    try {
      return await _channel.invokeMethod<bool>('openBatteryOptimization') ??
          false;
    } catch (_) {
      return false;
    }
  }
}
