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

  /// ── Notification copy pool (Bible-in-a-Year variants) ──────────
  /// Rotated deterministically by fire count so the same user sees all
  /// variants over time without true randomness.
  static const List<(String, String)> _morningBibleVariants = [
    ('A chapter today',                  'Day {n} is ready when you are. Open the Word.'),
    ('Still here. Still loved.',         'Begin Day {n} in two minutes of reading.'),
    ('The Word is waiting, friend.',     'Day {n}. One chapter, one breath.'),
    ('A new day, a new chapter',         'Day {n}. Press play on today’s reading.'),
    ('Sit with the Word',                'Day {n}. Slow down. Read. Let it find you.'),
    ('Quiet start',                      'Day {n}. A psalm, a proverb, a promise.'),
    ('Come as you are',                  'The Bible is not a test. Day {n} is waiting.'),
    ('A short path, a long story',       'Day {n} of 365. You’re further than you think.'),
    ('Small steps, big book',            'Day {n}. Three chapters. Five minutes.'),
    ('The Word, today',                  'Day {n}. Whatever you give is enough.'),
  ];

  static const List<String> _missedDayVariants = [
    'You didn’t finish today’s reading. Tomorrow is a new day.',
    'No guilt — just grace. Pick it up when ready.',
    'Days are long, the Word is patient. Take up Day {n} next.',
    'Missed days are not lost days. Continue.',
    'A rested mind reads better. See you tomorrow.',
  ];

  static const List<String> _comebackVariants = [
    'Welcome back. Your Day {n} is ready.',
    'Grace covers what you missed. Begin again.',
    'A fresh start awaits. Day {n}.',
    'Still here. Still glad. Pick up where you left off.',
    'The story continues. Day {n} is yours.',
  ];

  static String _bibleTitleForToday(int fireCount) =>
      _morningBibleVariants[fireCount.abs() % _morningBibleVariants.length].$1;

  static String _bibleBodyForToday(int fireCount) {
    final tpl = _morningBibleVariants[fireCount.abs() % _morningBibleVariants.length].$2;
    return tpl.replaceAll('{n}', 'today');
  }

  static String _missedDayCopy(int fireCount, int missedCount) {
    final v = _missedDayVariants[fireCount.abs() % _missedDayVariants.length];
    return missedCount > 7
        ? '$v (You’re $missedCount days behind — we’ll catch up slowly.)'
        : v.replaceAll('{n}', 'today');
  }

  static String _comebackCopy(int fireCount, int missedCount) {
    final v = _comebackVariants[fireCount.abs() % _comebackVariants.length];
    return missedCount > 30
        ? '$v You’ve been away $missedCount days — pick up wherever feels right.'
        : v.replaceAll('{n}', 'today');
  }

  Future<void> scheduleMorningReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notif_morning_hour') ?? 7;
    final minute = prefs.getInt('notif_morning_minute') ?? 0;
    final fireCount = (prefs.getInt('notif_morning_fire_count') ?? 0);
    await prefs.setInt('notif_morning_fire_count', fireCount + 1);
    final title = _bibleTitleForToday(fireCount);
    final body = _bibleBodyForToday(fireCount);
    await _scheduleDaily(_morningId, hour, minute, title, body);
  }

  Future<void> scheduleEveningReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notif_evening_hour') ?? 21;
    final minute = prefs.getInt('notif_evening_minute') ?? 0;
    final missed = prefs.getInt('notif_missed_count') ?? 0;
    final fireCount = (prefs.getInt('notif_evening_fire_count') ?? 0);
    await prefs.setInt('notif_evening_fire_count', fireCount + 1);
    final body = missed > 0
        ? _missedDayCopy(fireCount, missed)
        : 'Set down the day. Let the room hold you.';
    await _scheduleDaily(_eveningId, hour, minute, 'A quiet evening', body);
  }

  /// Snapshot the user’s missed-Bible-day count so subsequent evening
  /// reminders rotate the missed-day pool correctly.
  Future<void> recordMissedBibleDays(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_missed_count', count);
  }

  /// Show a one-shot comeback notification when the user opens the app
  /// after 3+ days away. Idempotent via last_comeback_shown tracking.
  Future<void> showComebackNotification({
    required int lastShownDays,
    required int missedDays,
  }) async {
    if (missedDays < 3) return;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_comeback_shown') ?? 0;
    if (last >= lastShownDays) return;
    await prefs.setInt('last_comeback_shown', lastShownDays);
    if (kIsWeb) return;
    final fireCount = (prefs.getInt('notif_comeback_fire_count') ?? 0);
    await prefs.setInt('notif_comeback_fire_count', fireCount + 1);
    final body = _comebackCopy(fireCount, missedDays);
    await _plugin.show(
      9999,
      'Welcome back',
      body,
      _details(),
    );
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