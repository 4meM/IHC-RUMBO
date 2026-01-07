import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_model.dart';
import '../../../../core/utils/geometry_utils.dart';

/// Calcular el scoring de una ruta basado en distancias
/// Input: distancia caminando origen, distancia caminando destino, distancia en bus
/// Output: score total (menor es mejor)
double calculateRouteScore({
  required double walkToPickup,
  required double walkToDestination,
  required double busDistance,
}) {
  // Penalizar caminar más que tomar el bus
  const walkPenalty = 2.0;
  const busPenalty = 1.0;
  
  return (walkToPickup * walkPenalty) + 
         (walkToDestination * walkPenalty) + 
         (busDistance * busPenalty);
}

/// Encontrar el punto de recogida óptimo en una ruta
/// Input: posición origen, puntos de la ruta del bus
/// Output: punto más cercano y su índice en la ruta
({LatLng point, int index, double distance}) findOptimalPickupPoint(
  LatLng origin,
  List<LatLng> routePoints,
) {
  if (routePoints.isEmpty) {
    throw ArgumentError('La ruta no puede estar vacía');
  }
  
  int bestIndex = 0;
  double minDistance = calculateDistance(origin, routePoints.first);
  
  for (int i = 1; i < routePoints.length; i++) {
    final distance = calculateDistance(origin, routePoints[i]);
    if (distance < minDistance) {
      minDistance = distance;
      bestIndex = i;
    }
  }
  
  return (
    point: routePoints[bestIndex],
    index: bestIndex,
    distance: minDistance,
  );
}

/// Encontrar el punto de bajada óptimo en una ruta
/// Input: posición destino, puntos de la ruta del bus, índice de pickup
/// Output: punto más cercano después del pickup y su índice
({LatLng point, int index, double distance}) findOptimalDropoffPoint(
  LatLng destination,
  List<LatLng> routePoints,
  int pickupIndex,
) {
  if (routePoints.isEmpty || pickupIndex >= routePoints.length - 1) {
    throw ArgumentError('Parámetros inválidos para dropoff');
  }
  
  // Buscar solo después del punto de pickup
  int bestIndex = pickupIndex + 1;
  double minDistance = calculateDistance(destination, routePoints[bestIndex]);
  
  for (int i = pickupIndex + 2; i < routePoints.length; i++) {
    final distance = calculateDistance(destination, routePoints[i]);
    if (distance < minDistance) {
      minDistance = distance;
      bestIndex = i;
    }
  }
  
  return (
    point: routePoints[bestIndex],
    index: bestIndex,
    distance: minDistance,
  );
}

/// Verificar si una ruta pasa cerca del origen y destino
/// Input: ruta, origen, destino, distancia máxima permitida
/// Output: true si la ruta es viable
bool isRouteViable({
  required List<LatLng> routePoints,
  required LatLng origin,
  required LatLng destination,
  double maxWalkingDistance = 1000.0,
}) {
  if (routePoints.isEmpty) return false;
  
  final pickup = findOptimalPickupPoint(origin, routePoints);
  
  if (pickup.distance > maxWalkingDistance) return false;
  
  // Verificar que hay puntos después del pickup
  if (pickup.index >= routePoints.length - 1) return false;
  
  final dropoff = findOptimalDropoffPoint(
    destination,
    routePoints,
    pickup.index,
  );
  
  return dropoff.distance <= maxWalkingDistance;
}

/// Crear un segmento de ruta entre dos índices
/// Input: lista de puntos completa, índice inicio, índice fin
/// Output: sublista de puntos del segmento
List<LatLng> extractRouteSegment(
  List<LatLng> routePoints,
  int startIndex,
  int endIndex,
) {
  if (startIndex < 0 || endIndex >= routePoints.length || startIndex >= endIndex) {
    return [];
  }
  
  return routePoints.sublist(startIndex, endIndex + 1);
}

/// Calcular métricas completas de una ruta
/// Input: ruta, origen, destino
/// Output: todas las métricas de la ruta
({
  double walkToPickup,
  double walkToDestination,
  double busDistance,
  double totalScore,
  LatLng pickupPoint,
  LatLng dropoffPoint,
  int pickupIndex,
  int dropoffIndex,
})? calculateRouteMetrics({
  required List<LatLng> routePoints,
  required LatLng origin,
  required LatLng destination,
}) {
  if (routePoints.isEmpty) return null;
  
  final pickup = findOptimalPickupPoint(origin, routePoints);
  
  if (pickup.index >= routePoints.length - 1) return null;
  
  final dropoff = findOptimalDropoffPoint(
    destination,
    routePoints,
    pickup.index,
  );
  
  final busDistance = calculateDistanceBetweenIndices(
    pickup.index,
    dropoff.index,
    routePoints,
  );
  
  final score = calculateRouteScore(
    walkToPickup: pickup.distance,
    walkToDestination: dropoff.distance,
    busDistance: busDistance,
  );
  
  return (
    walkToPickup: pickup.distance,
    walkToDestination: dropoff.distance,
    busDistance: busDistance,
    totalScore: score,
    pickupPoint: pickup.point,
    dropoffPoint: dropoff.point,
    pickupIndex: pickup.index,
    dropoffIndex: dropoff.index,
  );
}

/// Filtrar rutas que no son viables
/// Input: lista de todas las rutas, origen, destino, distancia máxima caminando
/// Output: lista de rutas viables
List<BusRouteModel> filterViableRoutes({
  required List<BusRouteModel> routes,
  required LatLng origin,
  required LatLng destination,
  double maxWalkingDistance = 1000.0,
}) {
  return routes.where((route) {
    return isRouteViable(
      routePoints: route.coordinates,
      origin: origin,
      destination: destination,
      maxWalkingDistance: maxWalkingDistance,
    );
  }).toList();
}

/// Ordenar rutas por score (mejor primero)
/// Input: lista de rutas con sus métricas
/// Output: lista ordenada por score ascendente
List<T> sortRoutesByScore<T>(
  List<T> routes,
  double Function(T) getScore,
) {
  final sorted = List<T>.from(routes);
  sorted.sort((a, b) => getScore(a).compareTo(getScore(b)));
  return sorted;
}

/// Verificar si dos rutas se solapan geográficamente
/// Input: dos listas de puntos de ruta
/// Output: true si tienen puntos cercanos
bool doRoutesOverlap(
  List<LatLng> route1,
  List<LatLng> route2, {
  double thresholdMeters = 100.0,
}) {
  for (final point1 in route1) {
    for (final point2 in route2) {
      if (calculateDistance(point1, point2) < thresholdMeters) {
        return true;
      }
    }
  }
  return false;
}

/// Calcular tiempo estimado de viaje
/// Input: distancia caminando, distancia en bus
/// Output: tiempo en minutos
double estimateTravelTime({
  required double walkingDistanceMeters,
  required double busDistanceMeters,
}) {
  // Velocidades promedio
  const walkingSpeedMPS = 1.4; // metros por segundo (5 km/h)
  const busSpeedMPS = 5.0; // metros por segundo (18 km/h en tráfico urbano)
  
  final walkingTimeSeconds = walkingDistanceMeters / walkingSpeedMPS;
  final busTimeSeconds = busDistanceMeters / busSpeedMPS;
  
  // Convertir a minutos y agregar tiempo de espera del bus
  const busWaitTimeMinutes = 5.0;
  
  return (walkingTimeSeconds + busTimeSeconds) / 60 + busWaitTimeMinutes;
}
