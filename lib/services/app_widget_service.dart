import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service that coordinates syncing live data to native Android AppWidgets.
///
/// It writes state keys into [SharedPreferences] (which Android reads via
/// `context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)`).
/// Then, it triggers the native method channel to request immediate widget updates.
class AppWidgetService {
  static const MethodChannel _channel = MethodChannel('com.usherapp.usher_app/widget');

  // SharedPreferences keys (prefixed by 'flutter.' when saved by shared_preferences)
  static const String keyDutyStation = 'widget_duty_station';
  static const String keyDutyDate = 'widget_duty_date';
  static const String keyDutyRole = 'widget_duty_role';
  static const String keyDutyService = 'widget_duty_service';

  static const String keyTallyCount = 'widget_tally_count';
  static const String keyTallyService = 'widget_tally_service';

  static const String keyScriptureText = 'widget_scripture_text';
  static const String keyScriptureRef = 'widget_scripture_ref';
  static const String keyScriptureCategory = 'widget_scripture_category';

  /// Update the Upcoming Duty / Shift Widget
  static Future<void> updateDutyWidget({
    required String station,
    required String date,
    required String role,
    required String serviceType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyDutyStation, station);
      await prefs.setString(keyDutyDate, date);
      await prefs.setString(keyDutyRole, role);
      await prefs.setString(keyDutyService, serviceType);
      await triggerNativeUpdate();
    } catch (e) {
      debugPrint('[AppWidgetService] Error updating Duty widget: $e');
    }
  }

  /// Update the Live Attendance Tally Widget
  static Future<void> updateTallyWidget({
    required int count,
    required String serviceType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyTallyCount, count);
      await prefs.setString(keyTallyService, serviceType);
      await triggerNativeUpdate();
    } catch (e) {
      debugPrint('[AppWidgetService] Error updating Tally widget: $e');
    }
  }

  /// Update the Daily Scripture & Wisdom Widget
  static Future<void> updateScriptureWidget({
    required String text,
    required String reference,
    required String category,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyScriptureText, text);
      await prefs.setString(keyScriptureRef, reference);
      await prefs.setString(keyScriptureCategory, category);
      await triggerNativeUpdate();
    } catch (e) {
      debugPrint('[AppWidgetService] Error updating Scripture widget: $e');
    }
  }

  /// Trigger native Android widget managers to re-render RemoteViews immediately
  static Future<void> triggerNativeUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('updateAllWidgets');
    } catch (e) {
      debugPrint('[AppWidgetService] Native update failed: $e');
    }
  }

  /// Check if the app was launched by clicking an Android Widget
  static Future<Map<String, dynamic>?> getInitialWidgetRoute() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getInitialRoute');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('[AppWidgetService] Error reading widget launch route: $e');
    }
    return null;
  }

  /// Listen for widget clicks while the app is alive or backgrounded
  static void setWidgetClickListener(Function(Map<String, dynamic> data) onWidgetClick) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetClick') {
        final arguments = call.arguments;
        if (arguments is Map) {
          onWidgetClick(Map<String, dynamic>.from(arguments));
        }
      }
    });
  }
}
