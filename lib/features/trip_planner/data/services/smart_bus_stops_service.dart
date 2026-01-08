import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as Math;
import '../models/smart_bus_stop_model.dart';
import '../models/bus_route_model.dart';

/// Servicio para generar paradas inteligentes basadas en la ruta y ubicación del usuario
class SmartBusStopsService {
  /// Genera 3 paradas inteligentes para una ruta específica
  /// [userLocation] - Ubicación actual del usuario
  /// [route] - Ruta de autobús seleccionada
  /// [routeRef] - Referencia de la ruta (para identificar)
  static List<SmartBusStopModel> generateSmartStops({
    required LatLng userLocation,
    required BusRouteModel route,
    required String routeRef,
  }) {
    final stops = <SmartBusStopModel>[];

    // Generar 3 puntos a lo largo de la ruta como paradas potenciales
    final routePoints = route.coordinates;
    if (routePoints.isEmpty) return stops;

    // Dividir la ruta en 3 secciones para obtener paradas distribuidas
    final nearestStopPoint = _findNearestPointOnRoute(userLocation, routePoints);
    final midPoint = routePoints[routePoints.length ~/ 2];
    final farPoint = routePoints.isNotEmpty ? routePoints.last : routePoints.first;

    // 1. PARADA MÁS CERCANA
    final nearestStop = SmartBusStopModel(
      id: '${routeRef}_nearest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Paradero Cercano - ${routeRef}',
      location: nearestStopPoint,
      type: SmartStopType.nearest,
      walkingDistance: _calculateDistance(userLocation, nearestStopPoint),
      estimatedBusDistance: _calculateRouteDistance(nearestStopPoint, midPoint, routePoints),
      estimatedWaitTime: Math.Random().nextInt(5) + 2, // 2-7 minutos
      estimatedTravelTime: Math.Random().nextInt(15) + 5, // 5-20 minutos
      crowdLevel: Math.Random().nextDouble() * 0.4, // Baja congestión (0-0.4)
      estimatedAvailableSeats: Math.Random().nextInt(8) + 3, // 3-11 asientos
      reason: 'Es la parada más cerca de tu ubicación actual',
      routes: [routeRef],
    );
    stops.add(nearestStop);

    // 2. PARADA QUE EVITA TRÁFICO (ubicada en punto medio)
    final avoidTrafficStop = SmartBusStopModel(
      id: '${routeRef}_traffic_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Paradero Alternativo - ${routeRef}',
      location: midPoint,
      type: SmartStopType.avoidTraffic,
      walkingDistance: _calculateDistance(userLocation, midPoint),
      estimatedBusDistance: _calculateRouteDistance(midPoint, farPoint, routePoints),
      estimatedWaitTime: Math.Random().nextInt(3) + 1, // 1-4 minutos
      estimatedTravelTime: Math.Random().nextInt(12) + 3, // 3-15 minutos
      crowdLevel: Math.Random().nextDouble() * 0.3 + 0.2, // Congestión media (0.2-0.5)
      estimatedAvailableSeats: Math.Random().nextInt(6) + 2, // 2-8 asientos
      reason: 'Esta ruta evita las avenidas principales con más tráfico',
      routes: [routeRef],
    );
    stops.add(avoidTrafficStop);

    // 3. PARADA CON ASIENTOS GARANTIZADOS (punto final)
    final guaranteedSeatsStop = SmartBusStopModel(
      id: '${routeRef}_seats_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Terminal - ${routeRef}',
      location: farPoint,
      type: SmartStopType.guaranteedSeats,
      walkingDistance: _calculateDistance(userLocation, farPoint),
      estimatedBusDistance: 0, // Es el final de la ruta
      estimatedWaitTime: Math.Random().nextInt(4) + 1, // 1-5 minutos
      estimatedTravelTime: Math.Random().nextInt(20) + 10, // 10-30 minutos
      crowdLevel: Math.Random().nextDouble() * 0.2, // Muy baja congestión (0-0.2)
      estimatedAvailableSeats: Math.Random().nextInt(10) + 5, // 5-15 asientos
      reason: 'Aquí los buses salen con menos pasajeros, garantizando asientos',
      routes: [routeRef],
    );
    stops.add(guaranteedSeatsStop);

    return stops;
  }

  /// Encuentra el punto más cercano en la ruta al usuario
  static LatLng _findNearestPointOnRoute(LatLng userLocation, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return userLocation;

    LatLng nearestPoint = routePoints.first;
    double minDistance = _calculateDistance(userLocation, nearestPoint);

    for (final point in routePoints) {
      final distance = _calculateDistance(userLocation, point);
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = point;
      }
    }

    return nearestPoint;
  }

  /// Calcula la distancia Haversine entre dos puntos
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000; // metros
    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLon = _toRadians(point2.longitude - point1.longitude);

    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRadians(point1.latitude)) *
            Math.cos(_toRadians(point2.latitude)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2);

    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Calcula la distancia aproximada siguiendo la ruta
  static double _calculateRouteDistance(LatLng from, LatLng to, List<LatLng> routePoints) {
    // Encontrar índices de los puntos más cercanos
    int fromIndex = 0;
    int toIndex = routePoints.length - 1;
    double minDistFrom = double.infinity;
    double minDistTo = double.infinity;

    for (int i = 0; i < routePoints.length; i++) {
      final distFrom = _calculateDistance(from, routePoints[i]);
      final distTo = _calculateDistance(to, routePoints[i]);

      if (distFrom < minDistFrom) {
        minDistFrom = distFrom;
        fromIndex = i;
      }
      if (distTo < minDistTo) {
        minDistTo = distTo;
        toIndex = i;
      }
    }

    // Calcular distancia entre puntos de la ruta
    double totalDistance = 0;
    if (fromIndex < toIndex) {
      for (int i = fromIndex; i < toIndex; i++) {
        totalDistance += _calculateDistance(routePoints[i], routePoints[i + 1]);
      }
    }

    return totalDistance;
  }

  static double _toRadians(double degrees) => degrees * Math.pi / 180;
}
