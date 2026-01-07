import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';

/// ============================================
/// TRACKING POLYLINE HELPER
/// Funciones puras para crear polylines de tracking
/// Estilo: Programación Competitiva
/// ============================================

/// Crear polyline para caminar (gris entrecortado)
/// Input: id, lista de puntos
/// Output: Polyline configurado
Polyline createWalkingPolylineForTracking(String id, List<LatLng> points) {
  return Polyline(
    polylineId: PolylineId(id),
    points: points,
    color: Colors.grey,
    width: 4,
    patterns: [PatternItem.dash(10), PatternItem.gap(5)],
  );
}

/// Crear polyline para ruta de bus (azul sólido)
/// Input: id, lista de puntos
/// Output: Polyline configurado
Polyline createBusRoutePolylineForTracking(String id, List<LatLng> points) {
  return Polyline(
    polylineId: PolylineId(id),
    points: points,
    color: AppColors.primary,
    width: 5,
  );
}

/// Crear set completo de polylines para tracking
/// Input: origen, pickup, ruta del bus, dropoff, destino
/// Output: Set de polylines
Set<Polyline> createTrackingPolylines({
  required List<LatLng> busRoute,
  List<LatLng>? walkToPickup,
  List<LatLng>? walkToDestination,
}) {
  final polylines = <Polyline>{
    createBusRoutePolylineForTracking('bus_route', busRoute),
  };
  
  // Agregar línea entrecortada para caminar al pickup
  if (walkToPickup != null && walkToPickup.isNotEmpty) {
    polylines.add(createWalkingPolylineForTracking('walk_to_pickup', walkToPickup));
  }
  
  // Agregar línea entrecortada para caminar al destino
  if (walkToDestination != null && walkToDestination.isNotEmpty) {
    polylines.add(createWalkingPolylineForTracking('walk_to_destination', walkToDestination));
  }
  
  return polylines;
}
