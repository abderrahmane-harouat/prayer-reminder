import 'dart:ui';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';

class PrayerNotificationService {
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'prayer_notifications',
          channelName: 'مواقيت الصلاة',
          channelDescription: 'إشعارات أوقات الصلاة',
          defaultColor: const Color(0xFF2196F3),
          ledColor: const Color(0xFF2196F3),
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          enableVibration: false, // Disabled vibration
          playSound: true,
          soundSource: 'resource://raw/notification',
          locked: false,
          onlyAlertOnce: true, // Only alert once per notification
          criticalAlerts: true,
        )
      ],
      debug: kDebugMode,
    );

    await _requestPermission();
  }

  static Future<bool> _requestPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Request exact alarm permission for Android 12+
    if (isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.CriticalAlert,
          NotificationPermission.PreciseAlarms,
        ],
      );
    }

    if (kDebugMode) {
      print('Notification permission: $isAllowed');
    }

    return isAllowed;
  }

  static Future<void> schedulePrayerNotification({
    required String prayerName,
    required String arabicName,
    required String timeString,
    required DateTime scheduledTime,
  }) async {
    try {
      final int id = _getNotificationId(prayerName);
      final now = DateTime.now();

      // Check if the scheduled time has already passed today
      if (scheduledTime.isBefore(now)) {
        if (kDebugMode) {
          print(
              '⏰ Skipping $prayerName - time has passed (${scheduledTime.hour}:${scheduledTime.minute})');
        }
        return;
      }

      final hour = scheduledTime.hour;
      final minute = scheduledTime.minute;

      if (kDebugMode) {
        print(
            '📅 Scheduling $prayerName ($arabicName) at $hour:${minute.toString().padLeft(2, '0')}');
      }

      // Create notification with daily repetition
      final success = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'prayer_notifications',
          title: '🕌 وقت الصلاة',
          body: 'حان وقت صلاة $arabicName',
          category: NotificationCategory.Reminder,
          notificationLayout: NotificationLayout.Default,
          wakeUpScreen: true,
          fullScreenIntent: false, // Changed to false to avoid multiple alerts
          criticalAlert: true,
          displayOnBackground: true,
          displayOnForeground: true,
          locked: false,
          autoDismissible: true,
          showWhen: true,
          icon: 'resource://mipmap/ic_launcher',
          largeIcon: 'resource://mipmap/ic_launcher',
          payload: {
            'prayer': prayerName,
            'arabicName': arabicName,
            'time': timeString,
          },
        ),
        schedule: NotificationCalendar(
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true, // Repeats daily at the same time
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );

      if (kDebugMode) {
        if (success) {
          print('✅ Successfully scheduled $prayerName notification');
        } else {
          print('❌ Failed to schedule $prayerName notification');
        }
      }

      // Verify the notification was scheduled
      final scheduledNotifications =
          await AwesomeNotifications().listScheduledNotifications();
      if (kDebugMode) {
        print(
            '📋 Total scheduled notifications: ${scheduledNotifications.length}');
        for (var notif in scheduledNotifications) {
          print(
              '   - ID: ${notif.content?.id}, Title: ${notif.content?.title}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error scheduling notification for $prayerName: $e');
      }
    }
  }

  static int _getNotificationId(String prayerName) {
    // Use consistent IDs for each prayer
    const prayerIds = {
      'Fajr': 1,
      'Dhuhr': 2,
      'Asr': 3,
      'Maghrib': 4,
      'Isha': 5,
    };
    return prayerIds[prayerName] ?? prayerName.hashCode.abs();
  }

  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    if (kDebugMode) {
      print('🗑️ Cancelled all notifications');
    }
  }

  static Future<void> cancelNotification(int id) async {
    await AwesomeNotifications().cancel(id);
    if (kDebugMode) {
      print('🗑️ Cancelled notification with ID: $id');
    }
  }

  static Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }
}
