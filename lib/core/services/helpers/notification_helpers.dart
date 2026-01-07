/// Helpers para configuración de notificaciones
/// Estilo: Programación competitiva - una función = un problema

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ============================================================================
// FUNCIONES DE CONFIGURACIÓN DE CANALES
// ============================================================================

/// Crea configuración de canal Android para SMS
/// Input: ninguno
/// Output: AndroidNotificationChannel configurado para SMS
AndroidNotificationChannel createSMSChannel() {
  return const AndroidNotificationChannel(
    'sms_channel',
    'Mensajes SMS',
    description: 'Notificaciones de códigos de verificación',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );
}

/// Crea configuración de canal Android para alertas de viaje
/// Input: ninguno
/// Output: AndroidNotificationChannel configurado para alertas
AndroidNotificationChannel createTravelAlertChannel() {
  return const AndroidNotificationChannel(
    'travel_alert_channel',
    'Alertas de Viaje',
    description: 'Notificaciones sobre tu viaje en curso',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
}

/// Crea configuración de canal Android para seguimiento en background
/// Input: ninguno
/// Output: AndroidNotificationChannel configurado para background
AndroidNotificationChannel createBackgroundChannel() {
  return const AndroidNotificationChannel(
    'background_channel',
    'Servicio en segundo plano',
    description: 'Mantiene el servicio de seguimiento activo',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  );
}

/// Crea lista de todos los canales de la app
/// Input: ninguno
/// Output: Lista de AndroidNotificationChannel
List<AndroidNotificationChannel> getAllChannels() {
  return [
    createSMSChannel(),
    createTravelAlertChannel(),
    createBackgroundChannel(),
  ];
}

// ============================================================================
// FUNCIONES DE CONFIGURACIÓN DE SETTINGS
// ============================================================================

/// Crea configuración de inicialización para Android
/// Input: String con nombre del icono (opcional)
/// Output: AndroidInitializationSettings
AndroidInitializationSettings createAndroidSettings({
  String icon = '@mipmap/ic_launcher',
}) {
  return AndroidInitializationSettings(icon);
}

/// Crea configuración de inicialización completa
/// Input: String con nombre del icono (opcional)
/// Output: InitializationSettings para todas las plataformas
InitializationSettings createInitializationSettings({
  String icon = '@mipmap/ic_launcher',
}) {
  return InitializationSettings(
    android: createAndroidSettings(icon: icon),
  );
}

// ============================================================================
// FUNCIONES DE CONSTRUCCIÓN DE DETALLES DE NOTIFICACIÓN
// ============================================================================

/// Crea detalles de notificación para código SMS
/// Input: String con código de verificación
/// Output: AndroidNotificationDetails configurado
AndroidNotificationDetails createSMSNotificationDetails(String code) {
  return AndroidNotificationDetails(
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
      const AndroidNotificationAction(
        'copy_code',
        'Copiar código',
        showsUserInterface: false,
        cancelNotification: false,
      ),
    ],
    category: AndroidNotificationCategory.message,
    fullScreenIntent: false,
  );
}

/// Crea detalles de notificación para alerta de proximidad
/// Input: String con nombre de parada, int con distancia en metros
/// Output: AndroidNotificationDetails configurado
AndroidNotificationDetails createProximityAlertDetails(String stopName, int meters) {
  return AndroidNotificationDetails(
    'travel_alert_channel',
    'Alertas de Viaje',
    channelDescription: 'Notificaciones sobre tu viaje en curso',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
    largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    styleInformation: BigTextStyleInformation(
      'Estás a $meters metros de tu parada "$stopName".\n\nPrepárate para bajar.',
      htmlFormatBigText: false,
      contentTitle: '¡Próxima parada!',
      summaryText: 'RUMBO',
    ),
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: true,
  );
}

/// Crea detalles de notificación para servicio en background
/// Input: String con texto descriptivo
/// Output: AndroidNotificationDetails configurado
AndroidNotificationDetails createBackgroundServiceDetails(String text) {
  return AndroidNotificationDetails(
    'background_channel',
    'Servicio en segundo plano',
    channelDescription: 'Mantiene el servicio de seguimiento activo',
    importance: Importance.low,
    priority: Priority.low,
    showWhen: false,
    playSound: false,
    enableVibration: false,
    ongoing: true,
    autoCancel: false,
    styleInformation: BigTextStyleInformation(
      text,
      htmlFormatBigText: false,
      contentTitle: 'RUMBO en segundo plano',
    ),
    category: AndroidNotificationCategory.service,
  );
}

/// Crea NotificationDetails envolviendo AndroidNotificationDetails
/// Input: AndroidNotificationDetails
/// Output: NotificationDetails para multiplataforma
NotificationDetails wrapNotificationDetails(AndroidNotificationDetails androidDetails) {
  return NotificationDetails(android: androidDetails);
}

// ============================================================================
// FUNCIONES DE FORMATO DE CÓDIGO
// ============================================================================

/// Formatea código de verificación con guión en medio
/// Input: String con 6 dígitos "123456"
/// Output: String formateado "123-456"
String formatVerificationCode(String code) {
  if (code.length != 6) return code;
  return '${code.substring(0, 3)}-${code.substring(3)}';
}

/// Genera texto completo para notificación de código
/// Input: String con código
/// Output: String con mensaje completo
String generateCodeNotificationText(String code) {
  return 'Tu código RUMBO es: $code\n\nToca "Copiar código" abajo para copiarlo.';
}

/// Genera título de notificación según tipo
/// Input: String con tipo de notificación
/// Output: String con título apropiado
String getNotificationTitle(String type) {
  switch (type) {
    case 'sms':
      return 'Código de verificación RUMBO';
    case 'proximity':
      return '¡Próxima parada!';
    case 'arrived':
      return '¡Llegaste a tu destino!';
    case 'background':
      return 'RUMBO en segundo plano';
    default:
      return 'RUMBO';
  }
}

// ============================================================================
// FUNCIONES DE GENERACIÓN DE IDs
// ============================================================================

/// Genera ID único para notificación basado en timestamp
/// Input: ninguno
/// Output: int con ID único
int generateNotificationId() {
  return DateTime.now().millisecondsSinceEpoch % 100000;
}

/// Obtiene ID fijo para notificación de código SMS
/// Input: ninguno
/// Output: int con ID fijo
int getSMSNotificationId() {
  return 0;
}

/// Obtiene ID fijo para notificación de proximidad
/// Input: ninguno
/// Output: int con ID fijo
int getProximityNotificationId() {
  return 1;
}

/// Obtiene ID fijo para notificación de background service
/// Input: ninguno
/// Output: int con ID fijo
int getBackgroundServiceNotificationId() {
  return 100;
}
