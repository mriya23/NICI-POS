import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    // Android Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Linux Settings (Optional, but good for desktop)
    final LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    // Combine Settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          linux: initializationSettingsLinux,
          // iOS/macOS settings can be added here if needed
        );

    await _notificationsPlugin.initialize(initializationSettings);
    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> showShiftOpenedNotification(
    String userName,
    double startCash,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'shift_channel',
          'Shift Notifications',
          channelDescription: 'Notifications for shift updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      'Kasir Dibuka',
      'Kasir $userName memulai shift dengan modal ${currencyFormat.format(startCash)}',
      platformChannelSpecifics,
    );
  }

  Future<void> showShiftClosedNotification(
    String userName,
    double actualCash,
    double difference,
  ) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'shift_channel',
          'Shift Notifications',
          channelDescription: 'Notifications for shift updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    String diffText = '';
    if (difference == 0) {
      diffText = 'Balance Aman';
    } else if (difference > 0) {
      diffText = 'Surplus +${currencyFormat.format(difference)}';
    } else {
      diffText = 'Defisit ${currencyFormat.format(difference)}';
    }

    await _notificationsPlugin.show(
      1,
      'Kasir Ditutup',
      'Kasir $userName menutup shift. Total Fisik: ${currencyFormat.format(actualCash)}. ($diffText)',
      platformChannelSpecifics,
    );
  }
}
