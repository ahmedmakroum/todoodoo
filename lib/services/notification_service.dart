import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import '../models/task_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    if (_initialized) return;
    
    if (!Platform.isLinux) {
      // Initialize timezone
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
          
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) async {
          // Handle notification tap
        },
      );
      
      // Request permissions for Android
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        await androidImplementation?.requestNotificationsPermission();
      }
      
      _initialized = true;
    }
  }

  Future<void> scheduleTaskNotification(TaskModel task) async {
    if (Platform.isLinux || task.dueDate == null) return;

    final androidNotificationDetails = AndroidNotificationDetails(
      'deadlines',
      'Task Deadlines',
      channelDescription: 'Notifications for task deadlines',
      importance: Importance.high,
      priority: Priority.high,
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    // Schedule deadline notification
    if (task.dueDate!.isAfter(DateTime.now())) {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        task.id!,
        'Task Due: ${task.title}',
        'This task is due now',
        tz.TZDateTime.from(task.dueDate!, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      // Schedule reminder 1 hour before
      final reminderTime = task.dueDate!.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          task.id! + 10000,
          'Upcoming Task: ${task.title}',
          'This task is due in 1 hour',
          tz.TZDateTime.from(reminderTime, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    // Schedule repeating notifications if task repeats
    if (task.repeats) {
      await flutterLocalNotificationsPlugin.periodicallyShow(
        task.id! + 20000,
        'Recurring Task: ${task.title}',
        'This task repeats daily',
        RepeatInterval.daily,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelNotification(int taskId) async {
    if (Platform.isLinux) return;
    
    // Cancel all notifications related to this task
    await flutterLocalNotificationsPlugin.cancel(taskId); // Main deadline
    await flutterLocalNotificationsPlugin.cancel(taskId + 10000); // Reminder
    await flutterLocalNotificationsPlugin.cancel(taskId + 20000); // Recurring
  }
}