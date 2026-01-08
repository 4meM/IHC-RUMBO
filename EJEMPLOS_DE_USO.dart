/// EJEMPLOS DE USO - Nueva Arquitectura Modular
/// Cada función hace UNA cosa. Como programación competitiva.

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'lib/core/utils/geometry_utils.dart';
import 'lib/core/utils/map_marker_factory.dart';
import 'lib/core/utils/map_polyline_factory.dart';
import 'lib/core/services/geolocation_helper.dart';
import 'lib/core/services/places_api_helper.dart';
import 'lib/features/trip_planner/data/helpers/route_calculation_helper.dart';

void ejemplosDeUso() async {
  // ============================================
  // EJEMPLO 1: Calcular distancia entre dos puntos
  // ============================================
  // ENTRADA: Dos coordenadas
  final puntoA = LatLng(-16.409, -71.537); // Plaza de Arequipa
  final puntoB = LatLng(-16.4003, -71.5300); // Cerca del Misti
  
  // SALIDA: Distancia en metros
  // Asegúrate de que calculateDistance esté implementada en geometry_utils.dart
  final distanciaMetros = calculateDistance(puntoA, puntoB);
  print('Distancia: $distanciaMetros metros'); // ~1200 metros
  
  // Formatear para mostrar al usuario
  final distanciaTexto = formatDistance(distanciaMetros);
  print('Distancia legible: $distanciaTexto'); // "1.2km"
  
  
  // ============================================
  // EJEMPLO 2: Encontrar el punto más cercano
  // ============================================
  // ENTRADA: Un punto objetivo y lista de candidatos
  final objetivo = LatLng(-16.409, -71.537);
  final paradas = [
    LatLng(-16.410, -71.538),
    LatLng(-16.405, -71.530), // ← Esta es la más cercana
    LatLng(-16.420, -71.550),
  ];
  
  // SALIDA: Punto más cercano y su distancia
  // Asegúrate de que findClosestPoint esté implementada en geometry_utils.dart
  final resultado = findClosestPoint(objetivo, paradas);
  print('Parada más cercana: ${resultado.point}');
  print('A ${resultado.distance.toStringAsFixed(0)}m de distancia');
  
  
  // ============================================
  // EJEMPLO 3: Crear marcadores para el mapa
  // ============================================
  // ENTRADA: Coordenadas de origen y destino
  final origen = LatLng(-16.409, -71.537);
  final destino = LatLng(-16.400, -71.530);
  
  // SALIDA: Set de marcadores listos para mostrar
  // Asegúrate de que createOriginDestinationMarkers esté implementada en map_marker_factory.dart
  final marcadores = createOriginDestinationMarkers(origen, destino);
  
  // También puedes crear marcadores individuales:
  final marcadorVerde = createOriginMarker(origen);
  final marcadorRojo = createDestinationMarker(destino);
  final marcadorAzul = createPickupMarker(LatLng(-16.405, -71.535));
  
  
  // ============================================
  // EJEMPLO 4: Crear polylines para rutas
  // ============================================
  // ENTRADA: Puntos de la ruta del bus
  final rutaBus = [
    LatLng(-16.409, -71.537),
    LatLng(-16.408, -71.536),
    LatLng(-16.407, -71.535),
  ];
  
  // SALIDA: Polyline azul para mostrar en el mapa
  // Asegúrate de que createBusRoutePolyline esté implementada en map_polyline_factory.dart
  final polylineBus = createBusRoutePolyline('ruta_1', rutaBus);
  
  // Para caminar (gris y punteado)
  final polylineCaminar = createWalkingPolyline('camino_1', [
    origen,
    LatLng(-16.408, -71.536),
  ]);
  
  
  // ============================================
  // EJEMPLO 5: Obtener ubicación actual
  // ============================================
  // ENTRADA: Nada
  // SALIDA: Ubicación o error
  // Asegúrate de que getLocationSafely esté implementada en geolocation_helper.dart
  final ubicacion = await getLocationSafely();
  
  if (ubicacion.error != null) {
    print('Error: ${ubicacion.error}');
  } else {
    print('Tu ubicación: ${ubicacion.location}');
    final latLng = ubicacion.location!;
    // Ahora puedes usar latLng para lo que necesites
  }
  
  
  // ============================================
  // EJEMPLO 6: Buscar lugares en tiempo real
  // ============================================
  // ENTRADA: Texto de búsqueda
  final query = 'Plaza de Armas';
  
  // SALIDA: Lista de sugerencias
  // Asegúrate de que searchPlacesInArequipa esté implementada en places_api_helper.dart
  final sugerencias = await searchPlacesInArequipa(query);
  
  for (final sugerencia in sugerencias) {
    print(sugerencia['description']); // "Plaza de Armas, Arequipa, Peru"
    final placeId = sugerencia['place_id'];
    
    // Convertir a coordenadas
    final coordenadas = await placeIdToLatLng(placeId);
    print('Coordenadas: $coordenadas');
  }
  
  
  // ============================================
  // EJEMPLO 7: Calcular métricas de una ruta
  // ============================================
  // ENTRADA: Ruta del bus, origen y destino
  final rutaPuntos = [
    LatLng(-16.410, -71.540),
    LatLng(-16.408, -71.538),
    LatLng(-16.406, -71.536),
    LatLng(-16.404, -71.534),
  ];
  final miOrigen = LatLng(-16.409, -71.537);
  final miDestino = LatLng(-16.405, -71.535);
  
  // SALIDA: Todas las métricas calculadas
  // Asegúrate de que calculateRouteMetrics esté implementada en route_calculation_helper.dart
  final metricas = calculateRouteMetrics(
    routePoints: rutaPuntos,
    origin: miOrigen,
    destination: miDestino,
  );
  
  if (metricas != null) {
    print('Caminar al bus: ${formatDistance(metricas.walkToPickup)}');
    print('Distancia en bus: ${formatDistance(metricas.busDistance)}');
    print('Caminar al destino: ${formatDistance(metricas.walkToDestination)}');
    print('Punto de subida: ${metricas.pickupPoint}');
    print('Punto de bajada: ${metricas.dropoffPoint}');
    
    // Calcular tiempo estimado
    final tiempo = estimateTravelTime(
      walkingDistanceMeters: metricas.walkToPickup + metricas.walkToDestination,
      busDistanceMeters: metricas.busDistance,
    );
    print('Tiempo estimado: ${tiempo.toStringAsFixed(0)} minutos');
  }
  
  
  // ============================================
  // EJEMPLO 8: Verificar si una ruta es viable
  // ============================================
  // ENTRADA: Ruta, origen, destino, distancia máxima caminando
  // Asegúrate de que isRouteViable esté implementada en route_calculation_helper.dart
  final esViable = isRouteViable(
    routePoints: rutaPuntos,
    origin: miOrigen,
    destination: miDestino,
    maxWalkingDistance: 1000.0, // 1 km máximo
  );
  
  if (esViable) {
    print('✅ Esta ruta es viable');
  } else {
    print('❌ Ruta muy lejos para caminar');
  }
  
  
  // ============================================
  // EJEMPLO 9: Calcular bounding box
  // ============================================
  // ENTRADA: Lista de puntos
  final todosPuntos = [origen, destino, ...rutaPuntos];
  
  // SALIDA: Límites geográficos
  // Asegúrate de que calculateBounds esté implementada en geometry_utils.dart
  final limites = calculateBounds(todosPuntos);
  print('Southwest: ${limites.southwest}');
  print('Northeast: ${limites.northeast}');
  
  // Expandir con margen de 500 metros
  // Asegúrate de que expandBounds esté implementada en geometry_utils.dart
  final limitesExpandidos = expandBounds(limites, 500);
  
  
  // ============================================
  // EJEMPLO 10: Calcular punto central
  // ============================================
  // ENTRADA: Lista de puntos
  // Asegúrate de que calculateCentroid esté implementada en geometry_utils.dart
  final centro = calculateCentroid(todosPuntos);
  print('Centro geométrico: $centro');
  
  
  // ============================================
  // EJEMPLO 11: Calcular scoring de ruta
  // ============================================
  // ENTRADA: Distancias de caminar y bus
  // Asegúrate de que calculateRouteScore esté implementada en route_calculation_helper.dart
  final score = calculateRouteScore(
    walkToPickup: 300.0,      // 300m caminando al bus
    walkToDestination: 200.0,  // 200m del bus al destino
    busDistance: 2000.0,       // 2km en el bus
  );
  print('Score de la ruta: $score (menor es mejor)');
}

// ============================================
// EJEMPLO 12: Cómo asignar tareas a compañeros
// ============================================

/// TAREA 1: Implementar marcador de bus animado
/// Input: Posición del bus, ángulo de rotación
/// Output: Marker con ícono de bus rotado
/// Archivo: lib/core/utils/map_marker_factory.dart
Marker createAnimatedBusMarker(LatLng position, double rotation) {
  // TODO: Tu compañero implementa esto
  throw UnimplementedError('Pendiente de implementar');
}

/// TAREA 2: Calcular velocidad promedio en una ruta
/// Input: Lista de puntos con timestamps
/// Output: Velocidad en km/h
/// Archivo: lib/core/utils/geometry_utils.dart
double calculateAverageSpeed(List<({LatLng point, DateTime timestamp})> points) {
  // TODO: Tu compañero implementa esto
  throw UnimplementedError('Pendiente de implementar');
}

/// TAREA 3: Filtrar lugares por tipo (restaurantes, hoteles, etc)
/// Input: Lista de lugares, tipo deseado
/// Output: Lista filtrada
/// Archivo: lib/core/services/places_api_helper.dart
List<Map<String, dynamic>> filterPlacesByType(
  List<Map<String, dynamic>> places,
  String type,
) {
  // TODO: Tu compañero implementa esto
  throw UnimplementedError('Pendiente de implementar');
}

// ============================================
// VENTAJAS DE ESTE ENFOQUE
// ============================================
/*
1. ✅ FUNCIONES PURAS: Fáciles de testear
   - Input → Función → Output (predecible)

2. ✅ MODULAR: Cada archivo tiene una responsabilidad
   - Bug en distancias? → geometry_utils.dart
   - Bug en GPS? → geolocation_helper.dart

3. ✅ REUTILIZABLE: Usa las funciones en cualquier parte
   - calculateDistance() se puede usar en cualquier feature

4. ✅ TESTEABLE: Escribe tests unitarios fácilmente
   test('calculateDistance', () {
     final result = calculateDistance(puntoA, puntoB);
     expect(result, closeTo(1200, 10));
   });

5. ✅ TRABAJO EN EQUIPO: Divide y vencerás
   - Persona A: Implementa 5 funciones de geometry_utils
   - Persona B: Implementa 5 funciones de places_api_helper
   - Persona C: Crea widgets de UI
   - Todos trabajan en paralelo sin conflictos

6. ✅ DOCUMENTACIÓN AUTOMÁTICA: Cada función tiene su propósito
   - El comentario dice exactamente qué hace
   - Input y Output claros
*/
