import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bus_route_model.dart';
import '../helpers/geojson_parser_helper.dart';
import '../helpers/route_calculation_helper.dart';
import '../../../../core/utils/geometry_utils.dart';

// Clase para almacenar ruta con información de proximidad
class RouteWithScore {
  final RouteGroup route;
  final double distanceToOrigin;
  final double distanceToDestination;
  final double routeDistance;
  final double totalScore;
  final LatLng? pickupPoint;
  final LatLng? dropoffPoint;
  
  RouteWithScore({
    required this.route,
    required this.distanceToOrigin,
    required this.distanceToDestination,
    required this.routeDistance,
    required this.totalScore,
    this.pickupPoint,
    this.dropoffPoint,
  });
  
  double get totalWalkingDistance => distanceToOrigin + distanceToDestination;
  bool get isDirectRoute => totalScore < 1000;
  
  String get walkingDistanceText {
    return formatDistance(totalWalkingDistance);
  }
  
  String get busDistanceText {
    return formatDistance(routeDistance);
  }
}

class RouteGroup {
  final String ref;
  final BusRouteModel? outbound;
  final BusRouteModel? return_;
  
  late final LatLngBounds bounds;
  late final LatLng centerPoint;
  late final List<LatLng> allPoints;
  
  RouteGroup({
    required this.ref,
    this.outbound,
    this.return_,
  }) {
    _calculateSpatialInfo();
  }
  
  void _calculateSpatialInfo() {
    allPoints = [
      if (outbound != null) ...outbound!.coordinates,
      if (return_ != null) ...return_!.coordinates,
    ];
    
    if (allPoints.isEmpty) return;
    bounds = calculateBounds(allPoints);
    centerPoint = calculateCentroid(allPoints);
  }
  
  double getMinDistanceToPoint(LatLng point) {
    if (allPoints.isEmpty) return double.infinity;
    final result = findClosestPoint(point, allPoints);
    return result.distance;
  }
  
  LatLng? getClosestPointTo(LatLng point) {
    if (allPoints.isEmpty) return null;
    final result = findClosestPoint(point, allPoints);
    return result.point;
  }
  
  int? getClosestPointIndexTo(LatLng point) {
    if (allPoints.isEmpty) return null;
    return findClosestPointIndex(point, allPoints);
  }
  
  double? getRouteDistanceBetweenPoints(LatLng from, LatLng to) {
    final fromIndex = getClosestPointIndexTo(from);
    final toIndex = getClosestPointIndexTo(to);
    
    if (fromIndex == null || toIndex == null || toIndex <= fromIndex) {
      return null;
    }
    
    return calculateDistanceBetweenIndices(fromIndex, toIndex, allPoints);
  }
  
  bool passesNear(LatLng point, double radiusMeters) {
    return getMinDistanceToPoint(point) <= radiusMeters;
  }
  
  String get displayName => outbound?.ref ?? return_?.ref ?? ref;
  
  Set<Polyline> toPolylines() {
    final polylines = <Polyline>{};
    
    if (outbound != null && return_ != null) {
      final circuitPoints = <LatLng>[
        ...outbound!.coordinates,
        ...return_!.coordinates,
      ];
      
      polylines.add(
        Polyline(
          polylineId: PolylineId('${ref}_circuit'),
          points: circuitPoints,
          color: outbound!.color,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    } else if (outbound != null) {
      polylines.add(
        Polyline(
          polylineId: PolylineId('${outbound!.id}_single'),
          points: outbound!.coordinates,
          color: outbound!.color,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    } else if (return_ != null) {
      polylines.add(
        Polyline(
          polylineId: PolylineId('${return_!.id}_single'),
          points: return_!.coordinates,
          color: return_!.color,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
    
    return polylines;
  }
}

class GeoJsonParserService {
  List<RouteGroup>? _cachedRoutes;
  
  Future<List<BusRouteModel>> loadBusRoutes() async {
    try {
      print('📍 Cargando rutas de buses desde GeoJSON...');
      
      final jsonString = await loadGeoJsonFromAssets('assets/data-buses/export.geojson');
      final features = extractFeatures(jsonString);
      
      print('📍 Total de features encontradas: ${features.length}');
      
      final routes = features.map((feature) {
        try {
          return BusRouteModel.fromGeoJson(feature);
        } catch (e) {
          print('⚠️ Error parseando ruta: $e');
          return null;
        }
      }).whereType<BusRouteModel>().toList();
      
      print('✅ ${routes.length} rutas cargadas exitosamente');
      
      return routes;
    } catch (e) {
      print('❌ Error cargando GeoJSON: $e');
      return [];
    }
  }
  
  Future<List<RouteGroup>> loadGroupedRoutes() async {
    if (_cachedRoutes != null) {
      print('📦 Usando rutas en cache: ${_cachedRoutes!.length}');
      return _cachedRoutes!;
    }
    
    final routes = await loadBusRoutes();
    final groupedByRef = groupFeaturesByRef(routes);
    final groups = <RouteGroup>[];
    
    groupedByRef.forEach((ref, routeList) {
      if (routeList.length >= 2) {
        final outbound = routeList[0];
        final returnRoute = routeList[1];
        
        final startPoint = outbound.coordinates.first;
        final endPoint = returnRoute.coordinates.last;
        final distance = calculateDistance(startPoint, endPoint);
        
        if (distance < 500) {
          groups.add(RouteGroup(
            ref: ref,
            outbound: outbound,
            return_: returnRoute,
          ));
          print('✅ Circuito válido: $ref - Distancia cierre: ${distance.toStringAsFixed(0)}m');
        } else {
          print('❌ Circuito abierto descartado: $ref - Distancia: ${distance.toStringAsFixed(0)}m');
        }
      } else if (routeList.length == 1) {
        groups.add(RouteGroup(
          ref: ref,
          outbound: routeList[0],
        ));
      }
    });
    
    print('✅ ${groups.length} rutas válidas (circuitos cerrados)');
    _cachedRoutes = groups;
    return groups;
  }
  
  Future<List<RouteWithScore>> findBestRoutes({
    required LatLng origin,
    required LatLng destination,
    double maxWalkingDistanceMeters = 500,
  }) async {
    final allRoutes = await loadGroupedRoutes();
    final routesWithScore = <RouteWithScore>[];
    
    for (final route in allRoutes) {
      final distanceToOrigin = route.getMinDistanceToPoint(origin);
      final distanceToDestination = route.getMinDistanceToPoint(destination);
      
      if (distanceToOrigin > maxWalkingDistanceMeters || 
          distanceToDestination > maxWalkingDistanceMeters) {
        continue;
      }
      
      final pickupPoint = route.getClosestPointTo(origin);
      final dropoffPoint = route.getClosestPointTo(destination);
      
      if (pickupPoint == null || dropoffPoint == null) continue;
      
      final routeDistance = route.getRouteDistanceBetweenPoints(pickupPoint, dropoffPoint);
      
      if (routeDistance == null) {
        print('❌ Ruta ${route.ref} descartada: destino está atrás en el recorrido');
        continue;
      }
      
      final score = calculateRouteScore(
        walkDistanceToPickup: distanceToOrigin,
        walkDistanceFromDropoff: distanceToDestination,
        busDistance: routeDistance,
      );
      
      routesWithScore.add(RouteWithScore(
        route: route,
        distanceToOrigin: distanceToOrigin,
        distanceToDestination: distanceToDestination,
        routeDistance: routeDistance,
        totalScore: score,
        pickupPoint: pickupPoint,
        dropoffPoint: dropoffPoint,
      ));
    }
    
    routesWithScore.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    
    print('🔍 Encontradas ${routesWithScore.length} rutas válidas (dirección correcta)');
    return routesWithScore;
  }
  
  Future<BusRouteModel?> getRouteById(String id) async {
    final routes = await loadBusRoutes();
    try {
      return routes.firstWhere((route) => route.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<BusRouteModel>> searchRoutesByName(String query) async {
    final routes = await loadBusRoutes();
    return routes.where((route) {
      return route.name.toLowerCase().contains(query.toLowerCase()) ||
             route.ref.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}


class RouteGroup {
  final String ref;
  final BusRouteModel? outbound; // Ida
  final BusRouteModel? return_; // Vuelta
  
  // Información espacial para búsquedas rápidas
  late final LatLngBounds bounds;
  late final LatLng centerPoint;
  late final List<LatLng> allPoints;
  
  RouteGroup({
    required this.ref,
    this.outbound,
    this.return_,
  }) {
    _calculateSpatialInfo();
  }
  
  void _calculateSpatialInfo() {
    allPoints = [
      if (outbound != null) ...outbound!.coordinates,
      if (return_ != null) ...return_!.coordinates,
    ];
    
    if (allPoints.isEmpty) return;
    
    // Calcular bounding box
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;
    
    for (final point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }
    
    bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    // Punto central de la ruta
    centerPoint = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );
  }
  
  // Calcular distancia mínima desde un punto a cualquier punto de la ruta
  double getMinDistanceToPoint(LatLng point) {
    if (allPoints.isEmpty) return double.infinity;
    
    double minDistance = double.infinity;
    for (final routePoint in allPoints) {
      final distance = _calculateDistanceBetween(
        point.latitude,
        point.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }
  
  // Encontrar el punto más cercano de la ruta a una ubicación dada
  LatLng? getClosestPointTo(LatLng point) {
    if (allPoints.isEmpty) return null;
    
    LatLng? closestPoint;
    double minDistance = double.infinity;
    
    for (final routePoint in allPoints) {
      final distance = _calculateDistanceBetween(
        point.latitude,
        point.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = routePoint;
      }
    }
    return closestPoint;
  }
  
  // Encontrar el ÍNDICE del punto más cercano (para verificar dirección)
  int? getClosestPointIndexTo(LatLng point) {
    if (allPoints.isEmpty) return null;
    
    int? closestIndex;
    double minDistance = double.infinity;
    
    for (int i = 0; i < allPoints.length; i++) {
      final routePoint = allPoints[i];
      final distance = _calculateDistanceBetween(
        point.latitude,
        point.longitude,
        routePoint.latitude,
        routePoint.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    return closestIndex;
  }
  
  // Calcular distancia de recorrido entre dos puntos (siguiendo la ruta)
  double? getRouteDistanceBetweenPoints(LatLng from, LatLng to) {
    final fromIndex = getClosestPointIndexTo(from);
    final toIndex = getClosestPointIndexTo(to);
    
    if (fromIndex == null || toIndex == null) return null;
    
    // Si el destino está ANTES que el origen en el recorrido, 
    // significa que hay que dar toda la vuelta
    if (toIndex <= fromIndex) {
      return null; // Ruta no conveniente
    }
    
    // Calcular distancia siguiendo la ruta
    double distance = 0;
    for (int i = fromIndex; i < toIndex; i++) {
      distance += _calculateDistanceBetween(
        allPoints[i].latitude,
        allPoints[i].longitude,
        allPoints[i + 1].latitude,
        allPoints[i + 1].longitude,
      );
    }
    
    return distance;
  }
  
  // Función helper estática para calcular distancia entre dos puntos
  static double _calculateDistanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // metros
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
  
  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  // Verificar si la ruta pasa cerca de un punto (radio en metros)
  bool passesNear(LatLng point, double radiusMeters) {
    return getMinDistanceToPoint(point) <= radiusMeters;
  }
  
  String get displayName => outbound?.ref ?? return_?.ref ?? ref;
  
  Set<Polyline> toPolylines() {
    final polylines = <Polyline>{};
    
    // Si tenemos ambas direcciones, crear un circuito cerrado
    if (outbound != null && return_ != null) {
      final circuitPoints = <LatLng>[
        ...outbound!.coordinates,
        ...return_!.coordinates,
      ];
      
      polylines.add(
        Polyline(
          polylineId: PolylineId('${ref}_circuit'),
          points: circuitPoints,
          color: outbound!.color,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    } 
    // Si solo hay una dirección
    else if (outbound != null) {
      polylines.add(
        Polyline(
          polylineId: PolylineId('${outbound!.id}_single'),
          points: outbound!.coordinates,
          color: outbound!.color,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    } else if (return_ != null) {
      polylines.add(
        Polyline(
          polylineId: PolylineId('${return_!.id}_single'),
          points: return_!.coordinates,
          color: return_!.color,
          width: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
    
    return polylines;
  }
}

class GeoJsonParserService {
  List<RouteGroup>? _cachedRoutes; // Cache para evitar recargar
  
  Future<List<BusRouteModel>> loadBusRoutes() async {
    try {
      print('📍 Cargando rutas de buses desde GeoJSON...');
      
      final String jsonString = await rootBundle.loadString(
        'assets/data-buses/export.geojson',
      );
      
      final Map<String, dynamic> geoJson = json.decode(jsonString);
      final List features = geoJson['features'] as List;
      
      print('📍 Total de features encontradas: ${features.length}');
      
      final routes = features.map((feature) {
        try {
          return BusRouteModel.fromGeoJson(feature);
        } catch (e) {
          print('⚠️ Error parseando ruta: $e');
          return null;
        }
      }).whereType<BusRouteModel>().toList();
      
      print('✅ ${routes.length} rutas cargadas exitosamente');
      
      return routes;
    } catch (e) {
      print('❌ Error cargando GeoJSON: $e');
      return [];
    }
  }
  
  Future<List<RouteGroup>> loadGroupedRoutes() async {
    // Usar cache si ya se cargaron
    if (_cachedRoutes != null) {
      print('📦 Usando rutas en cache: ${_cachedRoutes!.length}');
      return _cachedRoutes!;
    }
    
    final routes = await loadBusRoutes();
    final Map<String, List<BusRouteModel>> groupedByRef = {};
    
    // Agrupar por ref
    for (var route in routes) {
      if (route.ref.isEmpty) continue;
      
      if (!groupedByRef.containsKey(route.ref)) {
        groupedByRef[route.ref] = [];
      }
      groupedByRef[route.ref]!.add(route);
    }
    
    // Crear RouteGroups solo si forman circuitos cerrados
    final groups = <RouteGroup>[];
    groupedByRef.forEach((ref, routeList) {
      if (routeList.length >= 2) {
        final outbound = routeList[0];
        final returnRoute = routeList[1];
        
        // Verificar si forman un circuito cerrado
        final startPoint = outbound.coordinates.first;
        final endPoint = returnRoute.coordinates.last;
        final distance = RouteGroup._calculateDistanceBetween(
          startPoint.latitude, 
          startPoint.longitude,
          endPoint.latitude, 
          endPoint.longitude,
        );
        
        // Si están a menos de 500 metros, es un circuito válido
        if (distance < 500) {
          groups.add(RouteGroup(
            ref: ref,
            outbound: outbound,
            return_: returnRoute,
          ));
          print('✅ Circuito válido: $ref - Distancia cierre: ${distance.toStringAsFixed(0)}m');
        } else {
          print('❌ Circuito abierto descartado: $ref - Distancia: ${distance.toStringAsFixed(0)}m');
        }
      } else if (routeList.length == 1) {
        // Rutas con solo una dirección se mantienen
        groups.add(RouteGroup(
          ref: ref,
          outbound: routeList[0],
        ));
      }
    });
    
    print('✅ ${groups.length} rutas válidas (circuitos cerrados)');
    _cachedRoutes = groups; // Guardar en cache
    return groups;
  }
  
  // Buscar rutas que pasen cerca del origen Y destino
  Future<List<RouteWithScore>> findBestRoutes({
    required LatLng origin,
    required LatLng destination,
    double maxWalkingDistanceMeters = 500, // Máximo 500m caminando
  }) async {
    final allRoutes = await loadGroupedRoutes();
    final routesWithScore = <RouteWithScore>[];
    
    for (final route in allRoutes) {
      final distanceToOrigin = route.getMinDistanceToPoint(origin);
      final distanceToDestination = route.getMinDistanceToPoint(destination);
      
      // Filtrar rutas que estén demasiado lejos
      if (distanceToOrigin > maxWalkingDistanceMeters || 
          distanceToDestination > maxWalkingDistanceMeters) {
        continue;
      }
      
      final pickupPoint = route.getClosestPointTo(origin);
      final dropoffPoint = route.getClosestPointTo(destination);
      
      if (pickupPoint == null || dropoffPoint == null) continue;
      
      // VERIFICAR DIRECCIÓN: el destino debe estar ADELANTE en el recorrido
      final routeDistance = route.getRouteDistanceBetweenPoints(pickupPoint, dropoffPoint);
      
      if (routeDistance == null) {
        // El destino está "atrás" en el recorrido, habría que dar toda la vuelta
        print('❌ Ruta ${route.ref} descartada: destino está atrás en el recorrido');
        continue;
      }
      
      // Calcular score (menor es mejor)
      final score = distanceToOrigin + distanceToDestination + (routeDistance / 10);
      
      routesWithScore.add(RouteWithScore(
        route: route,
        distanceToOrigin: distanceToOrigin,
        distanceToDestination: distanceToDestination,
        routeDistance: routeDistance,
        totalScore: score,
        pickupPoint: pickupPoint,
        dropoffPoint: dropoffPoint,
      ));
    }
    
    // Ordenar por mejor score (menor distancia total)
    routesWithScore.sort((a, b) => a.totalScore.compareTo(b.totalScore));
    
    print('🔍 Encontradas ${routesWithScore.length} rutas válidas (dirección correcta)');
    return routesWithScore;
  }
  
  Future<BusRouteModel?> getRouteById(String id) async {
    final routes = await loadBusRoutes();
    try {
      return routes.firstWhere((route) => route.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<BusRouteModel>> searchRoutesByName(String query) async {
    final routes = await loadBusRoutes();
    return routes.where((route) {
      return route.name.toLowerCase().contains(query.toLowerCase()) ||
             route.ref.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
}
