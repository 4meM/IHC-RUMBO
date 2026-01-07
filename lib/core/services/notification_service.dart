import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'helpers/notification_helpers.dart';
import '../utils/clipboard_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    final initSettings = createInitializationSettings();
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    await _requestPermissions();
    await _createAllChannels();
        
    if (kDebugMode) {
      print('NotificationService inicializado correctamente');
    }
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _createAllChannels() async {
    final plugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (plugin != null) {
      for (final channel in getAllChannels()) {
        await plugin.createNotificationChannel(channel);
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) async {
    if (response.actionId == 'copy_code' && response.payload != null) {
      await copyToClipboard(response.payload!);
      if (kDebugMode) {
        print('Código copiado al portapapeles: ${response.payload}');
      }
    }
  }

  Future<void> showSMSNotification(String code) async {
    final androidDetails = createSMSNotificationDetails(code);
    final notificationDetails = wrapNotificationDetails(androidDetails);

    await _notifications.show(
      getSMSNotificationId(),
      getNotificationTitle('sms'),
      'Tu código es: $code - Toca para expandir',
      notificationDetails,
      payload: code,
    );
    
    final formattedCode = formatVerificationCode(code);
    await copyToClipboard(formattedCode);
    
    if (kDebugMode) {
      print('Notificación enviada con código: $code');
      print('Código copiado al portapapeles: $formattedCode');
    }
  }

  Future<void> showProximityAlert(String stopName, int meters) async {
    final androidDetails = createProximityAlertDetails(stopName, meters);
    final notificationDetails = wrapNotificationDetails(androidDetails);

    await _notifications.show(
      getProximityNotificationId(),
      getNotificationTitle('proximity'),
      'Estás cerca de: $stopName',
      notificationDetails,
    );
  }

  Future<void> showBackgroundServiceNotification(String text) async {
    final androidDetails = createBackgroundServiceDetails(text);
    final notificationDetails = wrapNotificationDetails(androidDetails);

    await _notifications.show(
      getBackgroundServiceNotificationId(),
      getNotificationTitle('background'),
      'Servicio activo',
      notificationDetails,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
