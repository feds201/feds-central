import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../util/constants.dart';
import 'match_notification_builder.dart';

/// Thin wrapper around flutter_local_notifications for match notifications.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  /// Called when the user taps a notification (foreground).
  void Function(String payload)? onTap;

  /// Set of notification IDs currently shown, for cancelling stale ones.
  final Set<int> _activeNotificationIds = {};

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Initialize the notification plugin and create channels.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Show/update notifications for upcoming matches.
  /// Cancels any previously shown notifications that are no longer in the list.
  Future<void> showMatchNotifications(List<MatchNotificationData> notifications) async {
    final newIds = notifications.map((n) => n.notificationId).toSet();

    // Cancel notifications that are no longer relevant
    for (final oldId in _activeNotificationIds) {
      if (!newIds.contains(oldId)) {
        await _plugin.cancel(oldId);
      }
    }
    _activeNotificationIds
      ..clear()
      ..addAll(newIds);

    for (final data in notifications) {
      await _showMatchNotification(data);
    }
  }

  Future<void> _showMatchNotification(MatchNotificationData data) async {
    final isRed = data.allianceSide == 'red';
    final channelId = isRed
        ? AppConstants.redChannelId
        : AppConstants.blueChannelId;
    final channelName = isRed
        ? 'Red Alliance Matches'
        : 'Blue Alliance Matches';
    final color = isRed ? Colors.red : Colors.blue;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for upcoming $channelName',
      importance: Importance.high,
      priority: Priority.high,
      color: color,
      usesChronometer: true,
      chronometerCountDown: true,
      when: data.chronometerTargetMs,
      styleInformation: BigTextStyleInformation(data.body),
      autoCancel: true,
      ongoing: false,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      data.notificationId,
      data.title,
      data.body,
      details,
      payload: data.payload,
    );
  }

  /// Cancel all match notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    _activeNotificationIds.clear();
  }

  /// Get the payload from a notification that launched the app (cold start).
  Future<String?> getInitialPayload() async {
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      return launchDetails!.notificationResponse?.payload;
    }
    return null;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && onTap != null) {
      onTap!(payload);
    }
  }
}
