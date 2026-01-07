/// ============================================
/// TRACKING NOTIFICATION HELPER
/// Funciones puras para crear notificaciones de tracking
/// Estilo: Programación Competitiva
/// ============================================

/// Crear mensaje de alarma activada
/// Input: ninguno
/// Output: mensaje
String getAlarmActivatedMessage() {
  return 'Alarma activada';
}

/// Crear mensaje de alarma desactivada
/// Input: ninguno
/// Output: mensaje
String getAlarmDeactivatedMessage() {
  return 'Alarma desactivada';
}

/// Crear mensaje de ubicación compartida
/// Input: ninguno
/// Output: mensaje
String getLocationSharedMessage() {
  return 'Ubicación compartida';
}

/// Crear mensaje de llamada a emergencia
/// Input: ninguno
/// Output: mensaje
String getEmergencyCallMessage() {
  return 'Llamando a emergencia';
}

/// Crear mensaje de mensaje enviado
/// Input: ninguno
/// Output: mensaje
String getMessageSentMessage() {
  return 'Mensaje enviado';
}

/// Crear mensaje de conductor notificado
/// Input: ninguno
/// Output: mensaje
String getDriverNotifiedMessage() {
  return 'Conductor notificado';
}

/// Crear mensaje cuando el bus está cerca
/// Input: distancia en km
/// Output: mensaje
String getBusNearMessage(String distanceKm) {
  return 'Bus a $distanceKm km - ¡Prepárate!';
}

/// Crear mensaje de llegada inminente
/// Input: minutos restantes
/// Output: mensaje
String getArrivalImminentMessage(int minutes) {
  return 'Bus llegará en $minutes minutos';
}

/// Verificar si debe mostrar notificación de cercanía
/// Input: distancia en km
/// Output: true si debe notificar
bool shouldNotifyBusProximity(double distanceKm) {
  return distanceKm <= 0.5; // 500 metros o menos
}

/// Verificar si debe activar alarma de llegada
/// Input: minutos restantes
/// Output: true si debe activar alarma
bool shouldTriggerArrivalAlarm(int minutesRemaining) {
  return minutesRemaining <= 3; // 3 minutos o menos
}
