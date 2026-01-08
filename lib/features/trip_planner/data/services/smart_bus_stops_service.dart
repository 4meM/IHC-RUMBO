import 'package:flutter/material.dart';
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

    // 1. Encontrar el paradero más cercano al usuario
    final nearestResult = _findNearestPointOnRouteWithIndex(userLocation, routePoints);
    final nearestStopPoint = nearestResult.point;
    final nearestIndex = nearestResult.index;
    
    // 2. Paradero que evita tráfico: más adelante del nearest (25% después en la ruta)
    final avoidTrafficIndex = (nearestIndex + (routePoints.length - nearestIndex) * 0.25).toInt().clamp(nearestIndex + 1, routePoints.length - 1);
    final avoidTrafficPoint = routePoints[avoidTrafficIndex];
    
    // 3. Paradero con asientos: al INICIO de la ruta (primeros 10% de puntos)
    final guaranteedSeatsIndex = (routePoints.length * 0.1).toInt().clamp(0, routePoints.length - 1);
    final guaranteedSeatsPoint = routePoints[guaranteedSeatsIndex];

    // 1. PARADA MÁS CERCANA
    final nearestStop = SmartBusStopModel(
      id: '${routeRef}_nearest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Paradero Cercano - ${routeRef}',
      location: nearestStopPoint,
      type: SmartStopType.nearest,
      walkingDistance: _calculateDistance(userLocation, nearestStopPoint),
      estimatedBusDistance: _calculateRouteDistance(nearestStopPoint, avoidTrafficPoint, routePoints),
      estimatedWaitTime: Math.Random().nextInt(5) + 2, // 2-7 minutos
      estimatedTravelTime: Math.Random().nextInt(15) + 5, // 5-20 minutos
      crowdLevel: Math.Random().nextDouble() * 0.4, // Baja congestión (0-0.4)
      estimatedAvailableSeats: Math.Random().nextInt(8) + 3, // 3-11 asientos
      reason: 'Es la parada más cerca de tu ubicación actual',
      routes: [routeRef],
    );
    stops.add(nearestStop);

    // 2. PARADA QUE EVITA TRÁFICO (más adelante del nearest)
    final avoidTrafficStop = SmartBusStopModel(
      id: '${routeRef}_traffic_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Paradero Alternativo - ${routeRef}',
      location: avoidTrafficPoint,
      type: SmartStopType.avoidTraffic,
      walkingDistance: _calculateDistance(userLocation, avoidTrafficPoint),
      estimatedBusDistance: _calculateRouteDistance(avoidTrafficPoint, guaranteedSeatsPoint, routePoints),
      estimatedWaitTime: Math.Random().nextInt(3) + 1, // 1-4 minutos
      estimatedTravelTime: Math.Random().nextInt(12) + 8, // 8-20 minutos
      crowdLevel: Math.Random().nextDouble() * 0.3 + 0.3, // Congestión media (0.3-0.6)
      estimatedAvailableSeats: Math.Random().nextInt(5) + 2, // 2-7 asientos
      reason: 'Más adelante en la ruta, evita zonas con tráfico pesado',
      routes: [routeRef],
    );
    stops.add(avoidTrafficStop);

    // 3. PARADA CON ASIENTOS GARANTIZADOS (al inicio de la ruta del bus)
    final guaranteedSeatsStop = SmartBusStopModel(
      id: '${routeRef}_seats_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Inicio de Ruta - ${routeRef}',
      location: guaranteedSeatsPoint,
      type: SmartStopType.guaranteedSeats,
      walkingDistance: _calculateDistance(userLocation, guaranteedSeatsPoint),
      estimatedBusDistance: _calculateRouteDistance(guaranteedSeatsPoint, nearestStopPoint, routePoints),
      estimatedWaitTime: Math.Random().nextInt(5) + 3, // 3-8 minutos
      estimatedTravelTime: Math.Random().nextInt(25) + 15, // 15-40 minutos
      crowdLevel: Math.Random().nextDouble() * 0.15, // Muy baja congestión (0-0.15)
      estimatedAvailableSeats: Math.Random().nextInt(12) + 8, // 8-20 asientos
      reason: 'Cerca del inicio de ruta, el bus aún no ha recogido muchos pasajeros',
      routes: [routeRef],
    );
    stops.add(guaranteedSeatsStop);

    return stops;
  }

  /// Genera paradas inteligentes usando directamente una lista de puntos de ruta
  /// Útil cuando no se dispone del `BusRouteModel` completo pero se tienen los puntos.
  static List<SmartBusStopModel> generateSmartStopsFromPoints({
    required LatLng userLocation,
    required List<LatLng> routePoints,
    required String routeRef,
  }) {
    final dummyRoute = BusRouteModel(
      id: routeRef,
      name: routeRef,
      ref: routeRef,
      from: '',
      to: '',
      coordinates: routePoints,
      color: Colors.blue,
    );

    return generateSmartStops(userLocation: userLocation, route: dummyRoute, routeRef: routeRef);
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

  /// Encuentra el punto más cercano en la ruta al usuario y retorna su índice
  static ({LatLng point, int index}) _findNearestPointOnRouteWithIndex(
    LatLng userLocation,
    List<LatLng> routePoints,
  ) {
    if (routePoints.isEmpty) return (point: userLocation, index: 0);

    LatLng nearestPoint = routePoints.first;
    int nearestIndex = 0;
    double minDistance = _calculateDistance(userLocation, nearestPoint);

    for (int i = 0; i < routePoints.length; i++) {
      final distance = _calculateDistance(userLocation, routePoints[i]);
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = routePoints[i];
        nearestIndex = i;
      }
    }

    return (point: nearestPoint, index: nearestIndex);
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
