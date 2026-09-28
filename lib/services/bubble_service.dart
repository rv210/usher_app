import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BubbleService {
  static const MethodChannel _channel = MethodChannel('com.usherapp.usher_app/bubble');
  static final FlutterLocalNotificationsPlugin _fallbackPlugin = FlutterLocalNotificationsPlugin();
  static bool _fallbackInitialized = false;

  /// Dispatches an Android Conversation Bubble Notification.
  /// On Android 11+ (API 30+), creates a floating system bubble linked to a long-lived shortcut.
  /// Falls back gracefully on iOS, Web, or older OS versions.
  static Future<bool> showBubbleNotification({
    required String senderName,
    required String message,
    String? senderId,
    String? shortcutId,
    bool autoExpand = false,
  }) async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _channel.invokeMethod<bool>('showBubble', {
          'senderName': senderName,
          'message': message,
          'senderId': senderId ?? 'team_lead',
          'shortcutId': shortcutId ?? 'comms_conversation',
          'autoExpand': autoExpand,
        });
        debugPrint("Android Bubble Notification triggered successfully: $result");
        return result ?? true;
      } on PlatformException catch (e) {
        debugPrint("Native Bubble Notification PlatformException: ${e.message}. Falling back to standard notification.");
      } catch (e) {
        debugPrint("Native Bubble Notification error: $e. Falling back to standard notification.");
      }
    }

    // Graceful fallback for non-Android or error
    return _showFallbackNotification(title: senderName, body: message);
  }

  static Future<bool> _showFallbackNotification({
    required String title,
    required String body,
  }) async {
    try {
      if (!_fallbackInitialized) {
        await _fallbackPlugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@drawable/ic_stat_notification'),
            iOS: DarwinInitializationSettings(),
          ),
        );
        _fallbackInitialized = true;
      }

      final id = (title.hashCode ^ body.hashCode) & 0x7FFFFFFF;
      await _fallbackPlugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Guardians Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notification',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint("Fallback notification failed: $e");
      return false;
    }
  }

  /// Dispatches an Android Duty Alert Notification following Google design guidelines:
  /// Monochromatic icon, gold accent, BigTextStyle, and Action buttons (View Station).
  static Future<bool> showDutyNotification({
    required String title,
    required String body,
    String stationName = "Sanctuary Main Doors",
    int targetTab = 0,
  }) async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final result = await _channel.invokeMethod<bool>('showDutyAlert', {
          'title': title,
          'body': body,
          'stationName': stationName,
          'targetTab': targetTab,
        });
        return result ?? true;
      } catch (e) {
        debugPrint("Native showDutyNotification error: $e");
      }
    }
    return _showFallbackNotification(title: title, body: body);
  }
}
