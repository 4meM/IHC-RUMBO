import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

/// ============================================
/// JOURNEY SIMULATION HELPER
/// Funciones puras para simulación de viaje
/// Clean Code: Responsabilidad única
/// ============================================

/// Ajustar punto a la polyline más cercana (snap to path)
LatLng snapToPolyline(LatLng point, List<LatLng> polyline) {
  if (polyline.isEmpty) return point;
  
  LatLng closest = polyline.first;
  double minDistance = _calculateDistance(point, closest);
  
  for (int i = 0; i < polyline.length - 1; i++) {
    final projected = _projectPointOnSegment(point, polyline[i], polyline[i + 1]);
    final distance = _calculateDistance(point, projected);
    
    if (distance < minDistance) {
      minDistance = distance;
      closest = projected;
    }
  }
  
  return closest;
}

/// Proyectar punto en un segmento de línea
LatLng _projectPointOnSegment(LatLng point, LatLng segmentStart, LatLng segmentEnd) {
  final dx = segmentEnd.longitude - segmentStart.longitude;
  final dy = segmentEnd.latitude - segmentStart.latitude;
  
  if (dx == 0 && dy == 0) return segmentStart;
  
  final t = ((point.longitude - segmentStart.longitude) * dx +
             (point.latitude - segmentStart.latitude) * dy) /
            (dx * dx + dy * dy);
  
  if (t < 0) return segmentStart;
  if (t > 1) return segmentEnd;
  
  return LatLng(
    segmentStart.latitude + t * dy,
    segmentStart.longitude + t * dx,
  );
}

/// Calcular distancia entre dos puntos (Haversine)
double _calculateDistance(LatLng p1, LatLng p2) {
  const R = 6371000; // Radio de la Tierra en metros
  final lat1 = p1.latitude * pi / 180;
  final lat2 = p2.latitude * pi / 180;
  final dLat = (p2.latitude - p1.latitude) * pi / 180;
  final dLon = (p2.longitude - p1.longitude) * pi / 180;
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return R * c;
}

/// Verificar si está en el mismo punto (tolerancia: 10 metros)
bool isAtSameLocation(LatLng p1, LatLng p2) {
  return _calculateDistance(p1, p2) < 10;
}

/// Verificar si está cerca (tolerancia: 100 metros ~ 1 cuadra)
bool isNearLocation(LatLng p1, LatLng p2) {
  return _calculateDistance(p1, p2) < 100;
}

/// Calcular progreso en ruta (0.0 a 1.0)
double calculateProgressOnRoute(LatLng point, List<LatLng> route) {
  if (route.length < 2) return 0.0;
  
  final snapped = snapToPolyline(point, route);
  double totalDistance = 0.0;
  double distanceToPoint = 0.0;
  bool foundPoint = false;
  
  for (int i = 0; i < route.length - 1; i++) {
    final segmentDistance = _calculateDistance(route[i], route[i + 1]);
    
    if (!foundPoint) {
      final distToStart = _calculateDistance(route[i], snapped);
      final distToEnd = _calculateDistance(snapped, route[i + 1]);
      
      if (distToStart + distToEnd - segmentDistance < 1) {
        distanceToPoint = totalDistance + distToStart;
        foundPoint = true;
      }
    }
    
    totalDistance += segmentDistance;
  }
  
  return totalDistance > 0 ? (distanceToPoint / totalDistance).clamp(0.0, 1.0) : 0.0;
}

/// Verificar si el bus va hacia el paradero (no ha pasado)
bool isBusApproachingStop(
  LatLng busPosition,
  double busProgress,
  LatLng stopPosition,
  double stopProgress,
  List<LatLng> route,
) {
  // El bus debe estar antes del paradero y acercándose
  return busProgress < stopProgress && (stopProgress - busProgress) < 0.1;
}

/// Calcular distancia restante en ruta
double calculateRemainingDistance(LatLng from, LatLng to, List<LatLng> route) {
  final fromProgress = calculateProgressOnRoute(from, route);
  final toProgress = calculateProgressOnRoute(to, route);
  
  if (toProgress <= fromProgress) return 0.0;
  
  double totalDistance = 0.0;
  bool counting = false;
  
  for (int i = 0; i < route.length - 1; i++) {
    final pointProgress = i / (route.length - 1);
    
    if (pointProgress >= fromProgress && pointProgress <= toProgress) {
      if (!counting) counting = true;
      if (counting) {
        totalDistance += _calculateDistance(route[i], route[i + 1]);
      }
    }
  }
  
  return totalDistance;
}
