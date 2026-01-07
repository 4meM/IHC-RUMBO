import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_model.dart';
import '../helpers/route_calculation_helper.dart';
import '../helpers/geojson_parser_helper.dart';

/// Resultado de búsqueda de rutas con toda la información necesaria
class RouteSearchResult {
  final String ref;
  final List<LatLng> routePoints;
  final double walkToPickup;
  final double walkToDestination;
  final double busDistance;
  final double totalScore;
  final LatLng pickupPoint;
  final LatLng dropoffPoint;
  final int pickupIndex;
  final int dropoffIndex;
  
  RouteSearchResult({
    required this.ref,
    required this.routePoints,
    required this.walkToPickup,
    required this.walkToDestination,
    required this.busDistance,
    required this.totalScore,
    required this.pickupPoint,
    required this.dropoffPoint,
    required this.pickupIndex,
    required this.dropoffIndex,
  });
  
  /// Obtener segmento de ruta entre pickup y dropoff
  List<LatLng> getBusSegment() {
    return extractRouteSegment(routePoints, pickupIndex, dropoffIndex);
  }
  
  /// Obtener tiempo estimado
  double getEstimatedTime() {
    return estimateTravelTime(
      walkingDistanceMeters: walkToPickup + walkToDestination,
      busDistanceMeters: busDistance,
    );
  }
}

/// Manager: Coordinar búsqueda y ranking de rutas de buses
/// Propósito único: Procesar origen/destino y retornar mejores rutas ordenadas
class RouteSearchManager {
  final Map<String, BusRouteModel> _allRoutes = {};
  
  /// Cargar todas las rutas desde GeoJSON
  Future<void> loadRoutesFromGeoJson(String assetPath) async {
    final geoJsonData = await loadGeoJsonFromAssets(assetPath);
    final features = extractFeatures(geoJsonData);
    final grouped = groupFeaturesByRef(features);
    
    // Procesar en lotes para no bloquear la UI
    int processed = 0;
    for (final entry in grouped.entries) {
      final ref = entry.key;
      final featuresGroup = entry.value;
      final routes = separateOutboundReturn(featuresGroup);
      
      if (routes.outbound != null) {
        _allRoutes['${ref}_outbound'] = BusRouteModel(
          id: '${ref}_outbound',
          name: ref,
          ref: ref,
          from: 'Ida',
          to: 'Destino',
          coordinates: routes.outbound!,
          color: Colors.blue,
        );
      }
      
      if (routes.return_ != null) {
        _allRoutes['${ref}_return'] = BusRouteModel(
          id: '${ref}_return',
          name: ref,
          ref: ref,
          from: 'Regreso',
          to: 'Origen',
          coordinates: routes.return_!,
          color: Colors.blue,
        );
      }
      
      // Dar respiro a la UI cada 10 rutas
      processed++;
      if (processed % 10 == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  }
  
  /// Buscar las mejores rutas entre origen y destino
  /// Input: coordenadas origen y destino, distancia máxima caminando
  /// Output: lista de resultados ordenada por score (mejor primero)
  List<RouteSearchResult> searchBestRoutes({
    required LatLng origin,
    required LatLng destination,
    double maxWalkingDistance = 1000.0,
    int maxResults = 5,
  }) {
    final results = <RouteSearchResult>[];
    
    // Evaluar cada ruta
    for (final entry in _allRoutes.entries) {
      final routeKey = entry.key;
      final route = entry.value;
      
      // Calcular métricas
      final metrics = calculateRouteMetrics(
        routePoints: route.coordinates,
        origin: origin,
        destination: destination,
      );
      
      if (metrics == null) continue;
      
      // Filtrar por distancia máxima caminando
      if (metrics.walkToPickup > maxWalkingDistance ||
          metrics.walkToDestination > maxWalkingDistance) {
        continue;
      }
      
      results.add(RouteSearchResult(
        ref: route.ref,
        routePoints: route.coordinates,
        walkToPickup: metrics.walkToPickup,
        walkToDestination: metrics.walkToDestination,
        busDistance: metrics.busDistance,
        totalScore: metrics.totalScore,
        pickupPoint: metrics.pickupPoint,
        dropoffPoint: metrics.dropoffPoint,
        pickupIndex: metrics.pickupIndex,
        dropoffIndex: metrics.dropoffIndex,
      ));
    }
    
    // Ordenar por score y limitar resultados
    final sorted = sortRoutesByScore(results, (r) => r.totalScore);
    
    return sorted.take(maxResults).toList();
  }
  
  /// Obtener estadísticas de las rutas cargadas
  ({int totalRoutes, int totalPoints}) getStats() {
    int totalPoints = 0;
    for (final route in _allRoutes.values) {
      totalPoints += route.coordinates.length;
    }
    
    return (
      totalRoutes: _allRoutes.length,
      totalPoints: totalPoints,
    );
  }
  
  /// Verificar si las rutas están cargadas
  bool get hasRoutes => _allRoutes.isNotEmpty;
  
  /// Obtener una ruta específica por su key
  BusRouteModel? getRoute(String routeKey) {
    return _allRoutes[routeKey];
  }
  
  /// Limpiar todas las rutas
  void clear() {
    _allRoutes.clear();
  }
}
