import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

/// ============================================
/// TRACKING CALCULATION HELPER
/// Funciones puras para cálculos de tracking
/// Estilo: Programación Competitiva
/// ============================================

/// Calcular distancia en kilómetros entre dos puntos
/// Input: dos coordenadas LatLng
/// Output: distancia en km (String formateado)
String calculateDistanceInKm(LatLng point1, LatLng point2) {
  const double earthRadius = 6371; // Radio de la Tierra en km

  final double lat1Rad = point1.latitude * pi / 180;
  final double lat2Rad = point2.latitude * pi / 180;
  final double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
  final double deltaLng = (point2.longitude - point1.longitude) * pi / 180;

  final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);

  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  final double distance = earthRadius * c;

  return distance.toStringAsFixed(1);
}

/// Calcular tiempo estimado de llegada en minutos
/// Input: distancia en km (String), velocidad promedio en km/h
/// Output: minutos (int)
int calculateEstimatedMinutes(String distanceKm, {double avgSpeed = 25.0}) {
  final double distance = double.tryParse(distanceKm) ?? 0;
  final double hours = distance / avgSpeed;
  final int minutes = (hours * 60).round();
  
  return minutes;
}

/// Formatear tiempo estimado a formato legible (HH:MM AM/PM)
/// Input: minutos desde ahora
/// Output: hora formateada
String formatEstimatedArrivalTime(int minutesFromNow) {
  final now = DateTime.now();
  final arrival = now.add(Duration(minutes: minutesFromNow));
  
  final hour = arrival.hour > 12 ? arrival.hour - 12 : arrival.hour;
  final period = arrival.hour >= 12 ? 'PM' : 'AM';
  final minute = arrival.minute.toString().padLeft(2, '0');
  
  return '$hour:$minute $period';
}

/// Calcular el punto central entre usuario y bus
/// Input: posición usuario, posición bus
/// Output: punto central
LatLng calculateMidpoint(LatLng userPos, LatLng busPos) {
  final double lat = (userPos.latitude + busPos.latitude) / 2;
  final double lng = (userPos.longitude + busPos.longitude) / 2;
  
  return LatLng(lat, lng);
}

/// Calcular nivel de zoom apropiado según distancia
/// Input: distancia en km
/// Output: nivel de zoom
double calculateZoomLevel(double distanceKm) {
  if (distanceKm < 0.5) return 16.0;
  if (distanceKm < 1.0) return 15.0;
  if (distanceKm < 2.0) return 14.0;
  if (distanceKm < 5.0) return 13.0;
  if (distanceKm < 10.0) return 12.0;
  return 11.0;
}

/// Verificar si el bus está cerca del usuario (menos de 500m)
/// Input: posición usuario, posición bus
/// Output: true si está cerca
bool isBusNearUser(LatLng userPos, LatLng busPos) {
  final distanceKm = double.tryParse(calculateDistanceInKm(userPos, busPos)) ?? 999;
  return distanceKm < 0.5; // Menos de 500 metros
}

/// Calcular bounds para incluir usuario y bus en el mapa
/// Input: posición usuario, posición bus
/// Output: LatLngBounds
LatLngBounds calculateBoundsForTracking(LatLng userPos, LatLng busPos) {
  final double minLat = min(userPos.latitude, busPos.latitude);
  final double maxLat = max(userPos.latitude, busPos.latitude);
  final double minLng = min(userPos.longitude, busPos.longitude);
  final double maxLng = max(userPos.longitude, busPos.longitude);
  
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}
