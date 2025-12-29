import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );
    
    // Configurar callback para manejar acciones de notificación
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // Solicitar permisos para Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // Crear canal de notificaciones
    const androidChannel = AndroidNotificationChannel(
      'sms_channel',
      'Mensajes SMS',
      description: 'Notificaciones de códigos de verificación',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
        
    if (kDebugMode) {
      print('NotificationService inicializado correctamente');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'copy_code') {
      final code = response.payload;
      if (code != null) {
        Clipboard.setData(ClipboardData(text: code));
        if (kDebugMode) {
          print('Código copiado al portapapeles: $code');
        }
      }
    }
  }

  Future<void> showSMSNotification(String code) async {
    final androidDetails = AndroidNotificationDetails(
      'sms_channel',
      'Mensajes SMS',
      channelDescription: 'Notificaciones de códigos de verificación',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        'Tu código RUMBO es: $code\n\nToca "Copiar código" abajo para copiarlo.',
        htmlFormatBigText: false,
        contentTitle: 'Código de verificación RUMBO',
        summaryText: 'RUMBO',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'copy_code',
          'Copiar código',
          showsUserInterface: false,
          cancelNotification: false,
        ),
      ],
      category: AndroidNotificationCategory.message,
      fullScreenIntent: false,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Código de verificación RUMBO',
      'Tu código es: $code - Toca para expandir',
      notificationDetails,
      payload: code,
    );
    
    // Copiar al portapapeles con formato (guión en medio)
    final formattedCode = '${code.substring(0, 3)}-${code.substring(3)}';
    await Clipboard.setData(ClipboardData(text: formattedCode));
    
    if (kDebugMode) {
      print('Notificación enviada con código: $code');
      print('Código copiado al portapapeles: $formattedCode');
    }
  }
}
