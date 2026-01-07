import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Crear una polyline básica para dibujar una ruta en el mapa
/// Input: ID único, lista de puntos, color, ancho
/// Output: Polyline configurada
Polyline createPolyline({
  required String id,
  required List<LatLng> points,
  required Color color,
  int width = 5,
}) {
  return Polyline(
    polylineId: PolylineId(id),
    points: points,
    color: color,
    width: width,
    geodesic: true,
  );
}

/// Crear una polyline para la ruta del bus (azul)
/// Input: ID de la ruta, puntos de la ruta
/// Output: Polyline azul para ruta de bus
Polyline createBusRoutePolyline(String routeId, List<LatLng> routePoints) {
  return createPolyline(
    id: 'bus_route_$routeId',
    points: routePoints,
    color: Colors.blue,
    width: 5,
  );
}

/// Crear una polyline para caminar (gris punteado)
/// Input: ID, puntos del camino a pie
/// Output: Polyline gris para caminar
Polyline createWalkingPolyline(String id, List<LatLng> walkingPoints) {
  return Polyline(
    polylineId: PolylineId('walking_$id'),
    points: walkingPoints,
    color: Colors.grey,
    width: 3,
    patterns: [PatternItem.dash(10), PatternItem.gap(5)],
    geodesic: true,
  );
}

/// Crear un set de polylines para una ruta completa (caminar + bus + caminar)
/// Input: puntos de caminar al origen, ruta del bus, puntos de caminar al destino
/// Output: Set con las 3 polylines
Set<Polyline> createCompleteRoutePolylines({
  required String routeId,
  required List<LatLng> walkToPickup,
  required List<LatLng> busRoute,
  required List<LatLng> walkToDestination,
}) {
  final polylines = <Polyline>{};
  
  if (walkToPickup.isNotEmpty) {
    polylines.add(createWalkingPolyline('origin_$routeId', walkToPickup));
  }
  
  if (busRoute.isNotEmpty) {
    polylines.add(createBusRoutePolyline(routeId, busRoute));
  }
  
  if (walkToDestination.isNotEmpty) {
    polylines.add(createWalkingPolyline('destination_$routeId', walkToDestination));
  }
  
  return polylines;
}

/// Crear polyline destacada (más ancha y con borde)
/// Input: ID, puntos, color principal
/// Output: Polyline destacada para ruta activa
Polyline createHighlightedPolyline({
  required String id,
  required List<LatLng> points,
  required Color color,
}) {
  return createPolyline(
    id: 'highlighted_$id',
    points: points,
    color: color,
    width: 8,
  );
}

/// Crear múltiples polylines de rutas de buses con colores diferentes
/// Input: mapa de ID de ruta -> puntos de la ruta, lista de colores
/// Output: Set de polylines coloreadas
Set<Polyline> createMultipleBusRoutePolylines(
  Map<String, List<LatLng>> routes,
  List<Color> colors,
) {
  final polylines = <Polyline>{};
  int colorIndex = 0;
  
  routes.forEach((routeId, points) {
    final color = colors[colorIndex % colors.length];
    polylines.add(createPolyline(
      id: routeId,
      points: points,
      color: color,
      width: 5,
    ));
    colorIndex++;
  });
  
  return polylines;
}

/// Crear polyline semitransparente para rutas inactivas
/// Input: ID, puntos de la ruta
/// Output: Polyline gris con transparencia
Polyline createInactiveRoutePolyline(String id, List<LatLng> points) {
  return createPolyline(
    id: 'inactive_$id',
    points: points,
    color: Colors.grey.withOpacity(0.4),
    width: 3,
  );
}
