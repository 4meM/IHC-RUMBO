import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Calcular distancia en metros entre dos puntos geográficos usando fórmula de Haversine
/// Input: dos coordenadas LatLng
/// Output: distancia en metros (double)
double calculateDistance(LatLng point1, LatLng point2) {
  const earthRadius = 6371000.0; // Radio de la Tierra en metros
  
  final lat1Rad = point1.latitude * pi / 180;
  final lat2Rad = point2.latitude * pi / 180;
  final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
  final deltaLng = (point2.longitude - point1.longitude) * pi / 180;
  
  final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) *
      sin(deltaLng / 2) * sin(deltaLng / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

/// Encontrar el punto más cercano de una lista a un punto objetivo
/// Input: punto objetivo, lista de puntos candidatos
/// Output: punto más cercano y su distancia
({LatLng point, double distance}) findClosestPoint(
  LatLng target,
  List<LatLng> candidates,
) {
  if (candidates.isEmpty) {
    throw ArgumentError('La lista de candidatos no puede estar vacía');
  }
  
  LatLng closestPoint = candidates.first;
  double minDistance = calculateDistance(target, closestPoint);
  
  for (final candidate in candidates.skip(1)) {
    final distance = calculateDistance(target, candidate);
    if (distance < minDistance) {
      minDistance = distance;
      closestPoint = candidate;
    }
  }
  
  return (point: closestPoint, distance: minDistance);
}

/// Calcular el bounding box (límites geográficos) de una lista de puntos
/// Input: lista de coordenadas
/// Output: LatLngBounds que contiene todos los puntos
LatLngBounds calculateBounds(List<LatLng> points) {
  if (points.isEmpty) {
    throw ArgumentError('La lista de puntos no puede estar vacía');
  }
  
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;
  
  for (final point in points.skip(1)) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }
  
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

/// Calcular el punto central (centroid) de una lista de coordenadas
/// Input: lista de puntos
/// Output: punto central promedio
LatLng calculateCentroid(List<LatLng> points) {
  if (points.isEmpty) {
    throw ArgumentError('La lista de puntos no puede estar vacía');
  }
  
  double totalLat = 0;
  double totalLng = 0;
  
  for (final point in points) {
    totalLat += point.latitude;
    totalLng += point.longitude;
  }
  
  return LatLng(
    totalLat / points.length,
    totalLng / points.length,
  );
}

/// Formatear distancia en metros a texto legible (m o km)
/// Input: distancia en metros
/// Output: string formateado ("150m" o "2.5km")
String formatDistance(double meters) {
  if (meters < 1000) {
    return '${meters.toStringAsFixed(0)}m';
  }
  return '${(meters / 1000).toStringAsFixed(1)}km';
}

/// Calcular la distancia acumulada a lo largo de una ruta (polilínea)
/// Input: lista de puntos que forman la ruta
/// Output: distancia total en metros
double calculateRouteDistance(List<LatLng> routePoints) {
  if (routePoints.length < 2) return 0.0;
  
  double totalDistance = 0.0;
  
  for (int i = 0; i < routePoints.length - 1; i++) {
    totalDistance += calculateDistance(routePoints[i], routePoints[i + 1]);
  }
  
  return totalDistance;
}

/// Verificar si un punto está dentro de un bounding box
/// Input: punto a verificar, límites del box
/// Output: true si está dentro, false si no
bool isPointInsideBounds(LatLng point, LatLngBounds bounds) {
  return point.latitude >= bounds.southwest.latitude &&
      point.latitude <= bounds.northeast.latitude &&
      point.longitude >= bounds.southwest.longitude &&
      point.longitude <= bounds.northeast.longitude;
}

/// Encontrar el índice del punto más cercano en una ruta
/// Input: punto objetivo, lista de puntos de la ruta
/// Output: índice del punto más cercano en la lista
int findClosestPointIndex(LatLng target, List<LatLng> routePoints) {
  if (routePoints.isEmpty) return -1;
  
  int closestIndex = 0;
  double minDistance = calculateDistance(target, routePoints.first);
  
  for (int i = 1; i < routePoints.length; i++) {
    final distance = calculateDistance(target, routePoints[i]);
    if (distance < minDistance) {
      minDistance = distance;
      closestIndex = i;
    }
  }
  
  return closestIndex;
}

/// Calcular la distancia entre dos puntos a lo largo de una ruta
/// Input: índices de inicio y fin, lista de puntos de la ruta
/// Output: distancia acumulada entre los dos puntos
double calculateDistanceBetweenIndices(
  int startIndex,
  int endIndex,
  List<LatLng> routePoints,
) {
  if (startIndex < 0 || endIndex >= routePoints.length || startIndex >= endIndex) {
    return 0.0;
  }
  
  double distance = 0.0;
  
  for (int i = startIndex; i < endIndex; i++) {
    distance += calculateDistance(routePoints[i], routePoints[i + 1]);
  }
  
  return distance;
}

/// Expandir un bounding box con un margen en metros
/// Input: bounds original, margen en metros
/// Output: bounds expandido
LatLngBounds expandBounds(LatLngBounds bounds, double marginMeters) {
  // Aproximación: 1 grado ≈ 111,000 metros
  final marginDegrees = marginMeters / 111000;
  
  return LatLngBounds(
    southwest: LatLng(
      bounds.southwest.latitude - marginDegrees,
      bounds.southwest.longitude - marginDegrees,
    ),
    northeast: LatLng(
      bounds.northeast.latitude + marginDegrees,
      bounds.northeast.longitude + marginDegrees,
    ),
  );
}
