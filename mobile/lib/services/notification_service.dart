// HEAL — Local notifications service.
// Schedules daily gentle reminders for morning + evening content.
// Uses flutter_local_notifications + timezone for cross-tz scheduling.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const _channelId = 'heal_daily';
  static const _channelName = 'HEAL · Daily Content';
  static const _channelDesc = 'Gentle reminders for morning and evening practice';
  static const _morningId = 1001;
  static const _eveningId = 1002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      // Web push notifications use Firebase Messaging, not flutter_local_notifications.
      // Skip init on web — the user can still set preferences which get honored on mobile.
      _initialized = true;
      return;
    }
    tzdata.initializeTimeZones();
    // Use device local timezone
    final localName = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(_mapTimezone(localName)));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const init = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(init);
    _initialized = true;
  }

  /// Map a system timezone name (e.g. "PST", "GMT+08:00") to an IANA name.
  String _mapTimezone(String sysName) {
    // Common mappings
    const map = {
      'PST': 'America/Los_Angeles',
      'PDT': 'America/Los_Angeles',
      'EST': 'America/New_York',
      'EDT': 'America/New_York',
      'CST': 'America/Chicago',
      'CDT': 'America/Chicago',
      'MST': 'America/Denver',
      'MDT': 'America/Denver',
      'BST': 'Europe/London',
      'CET': 'Europe/Paris',
      'CEST': 'Europe/Paris',
      'JST': 'Asia/Tokyo',
      'KST': 'Asia/Seoul',
      'IST': 'Asia/Kolkata',
      'SGT': 'Asia/Singapore',
      'HKT': 'Asia/Hong_Kong',
      'AEST': 'Australia/Sydney',
      'AEDT': 'Australia/Sydney',
    };
    for (final entry in map.entries) {
      if (sysName.contains(entry.key)) return entry.value;
    }
    return 'UTC';
  }

  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    } else if (Platform.isAndroid) {
      final granted = await _plugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
      return granted;
    }
    return true;
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> _scheduleDaily(
    int id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) print('Schedule error: $e');
    }
  }

  Future<void> scheduleMorningReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notif_morning_hour') ?? 7;
    final minute = prefs.getInt('notif_morning_minute') ?? 0;
    const title = 'A gentle morning awaits';
    const body = 'Take five minutes. Begin with stillness.';
    await _scheduleDaily(_morningId, hour, minute, title, body);
  }

  Future<void> scheduleEveningReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notif_evening_hour') ?? 21;
    final minute = prefs.getInt('notif_evening_minute') ?? 0;
    const title = 'A quiet evening';
    const body = 'Set down the day. Let the room hold you.';
    await _scheduleDaily(_eveningId, hour, minute, title, body);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> enable({bool morning = true, bool evening = true}) async {
    await init();
    final granted = await requestPermission();
    if (!granted) {
      if (kDebugMode) print('Notification permission not granted');
      return;
    }
    await cancelAll();
    if (morning) await scheduleMorningReminder();
    if (evening) await scheduleEveningReminder();
  }

  Future<void> disable() async {
    await init();
    await cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});