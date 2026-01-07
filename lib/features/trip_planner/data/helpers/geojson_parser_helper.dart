import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cargar y parsear archivo GeoJSON desde assets
/// Input: ruta del archivo en assets
/// Output: mapa con los datos parseados
Future<Map<String, dynamic>> loadGeoJsonFromAssets(String assetPath) async {
  final jsonString = await rootBundle.loadString(assetPath);
  return json.decode(jsonString) as Map<String, dynamic>;
}

/// Extraer todas las features de un GeoJSON
/// Input: mapa de datos GeoJSON
/// Output: lista de features
List<dynamic> extractFeatures(Map<String, dynamic> geoJsonData) {
  return geoJsonData['features'] as List<dynamic>? ?? [];
}

/// Convertir un array de coordenadas GeoJSON a LatLng
/// Input: array [lng, lat]
/// Output: LatLng
LatLng coordinateArrayToLatLng(List<dynamic> coord) {
  final lng = (coord[0] as num).toDouble();
  final lat = (coord[1] as num).toDouble();
  return LatLng(lat, lng);
}

/// Convertir lista de coordenadas GeoJSON a lista de LatLng
/// Input: array de coordenadas [[lng, lat], [lng, lat], ...] o MultiLineString [[[lng, lat], ...]]
/// Output: lista de LatLng
List<LatLng> parseCoordinates(List<dynamic> coordinates) {
  // Verificar si es un MultiLineString (tiene un nivel extra de anidación)
  if (coordinates.isNotEmpty && coordinates.first is List) {
    final firstElement = coordinates.first as List;
    // Si el primer elemento es también una lista de listas, es un MultiLineString
    if (firstElement.isNotEmpty && firstElement.first is List) {
      // Aplanar MultiLineString: tomar solo la primera línea
      return parseCoordinates(firstElement);
    }
  }
  
  // LineString normal
  return coordinates
      .map((coord) {
        if (coord is List && coord.length >= 2) {
          return coordinateArrayToLatLng(coord);
        }
        throw FormatException('Invalid coordinate format: $coord');
      })
      .toList();
}

/// Extraer el ID de referencia de una feature (ref, route_ref, etc.)
/// Input: propiedades de la feature
/// Output: string con el ID de referencia o null
String? extractRouteRef(Map<String, dynamic> properties) {
  return properties['ref'] as String? ??
      properties['route_ref'] as String? ??
      properties['name'] as String?;
}

/// Determinar si una ruta es de ida o vuelta basado en propiedades
/// Input: propiedades de la feature
/// Output: 'outbound', 'return' o 'unknown'
String determineRouteDirection(Map<String, dynamic> properties) {
  final direction = properties['direction'] as String?;
  final role = properties['role'] as String?;
  
  if (direction != null) {
    if (direction.toLowerCase().contains('forward') ||
        direction.toLowerCase().contains('ida')) {
      return 'outbound';
    }
    if (direction.toLowerCase().contains('backward') ||
        direction.toLowerCase().contains('vuelta')) {
      return 'return';
    }
  }
  
  if (role != null) {
    if (role.toLowerCase().contains('forward')) return 'outbound';
    if (role.toLowerCase().contains('backward')) return 'return';
  }
  
  return 'unknown';
}

/// Agrupar features por su referencia (ref)
/// Input: lista de todas las features
/// Output: mapa de ref -> lista de features
Map<String, List<Map<String, dynamic>>> groupFeaturesByRef(
  List<dynamic> features,
) {
  final grouped = <String, List<Map<String, dynamic>>>{};
  
  for (final feature in features) {
    final properties = feature['properties'] as Map<String, dynamic>? ?? {};
    final ref = extractRouteRef(properties);
    
    if (ref == null) continue;
    
    grouped.putIfAbsent(ref, () => []);
    grouped[ref]!.add({
      'coordinates': feature['geometry']['coordinates'] as List<dynamic>,
      'properties': properties,
      'direction': determineRouteDirection(properties),
    });
  }
  
  return grouped;
}

/// Separar rutas de ida y vuelta de un grupo
/// Input: lista de features del mismo ref
/// Output: mapa con 'outbound' y 'return' coordinates
({List<LatLng>? outbound, List<LatLng>? return_}) separateOutboundReturn(
  List<Map<String, dynamic>> featuresGroup,
) {
  List<LatLng>? outbound;
  List<LatLng>? return_;
  
  for (final feature in featuresGroup) {
    final coords = parseCoordinates(feature['coordinates'] as List<dynamic>);
    final direction = feature['direction'] as String;
    
    if (direction == 'outbound' && outbound == null) {
      outbound = coords;
    } else if (direction == 'return' && return_ == null) {
      return_ = coords;
    }
  }
  
  // Si no hay direcciones explícitas, usar la primera como outbound
  if (outbound == null && featuresGroup.isNotEmpty) {
    outbound = parseCoordinates(featuresGroup.first['coordinates'] as List<dynamic>);
  }
  
  return (outbound: outbound, return_: return_);
}

/// Validar que una ruta tenga suficientes puntos
/// Input: lista de coordenadas
/// Output: true si tiene al menos 2 puntos
bool isValidRoute(List<LatLng>? coordinates) {
  return coordinates != null && coordinates.length >= 2;
}

/// Filtrar rutas inválidas de un mapa
/// Input: mapa de ref -> routes
/// Output: mapa solo con rutas válidas
Map<String, dynamic> filterInvalidRoutes(Map<String, dynamic> routesMap) {
  final filtered = <String, dynamic>{};
  
  routesMap.forEach((ref, data) {
    final outbound = data['outbound'] as List<LatLng>?;
    final return_ = data['return'] as List<LatLng>?;
    
    if (isValidRoute(outbound) || isValidRoute(return_)) {
      filtered[ref] = data;
    }
  });
  
  return filtered;
}

/// Crear un resumen de estadísticas del GeoJSON
/// Input: mapa de routes
/// Output: estadísticas
({int totalRoutes, int withOutbound, int withReturn, int totalPoints}) 
calculateGeoJsonStats(Map<String, dynamic> routesMap) {
  int withOutbound = 0;
  int withReturn = 0;
  int totalPoints = 0;
  
  routesMap.forEach((ref, data) {
    final outbound = data['outbound'] as List<LatLng>?;
    final return_ = data['return'] as List<LatLng>?;
    
    if (outbound != null) {
      withOutbound++;
      totalPoints += outbound.length;
    }
    
    if (return_ != null) {
      withReturn++;
      totalPoints += return_.length;
    }
  });
  
  return (
    totalRoutes: routesMap.length,
    withOutbound: withOutbound,
    withReturn: withReturn,
    totalPoints: totalPoints,
  );
}

/// Extraer todos los puntos únicos de todas las rutas
/// Input: mapa de todas las rutas
/// Output: Set de todas las coordenadas únicas
Set<LatLng> extractAllUniquePoints(Map<String, dynamic> routesMap) {
  final allPoints = <LatLng>{};
  
  routesMap.forEach((ref, data) {
    final outbound = data['outbound'] as List<LatLng>?;
    final return_ = data['return'] as List<LatLng>?;
    
    if (outbound != null) allPoints.addAll(outbound);
    if (return_ != null) allPoints.addAll(return_);
  });
  
  return allPoints;
}
