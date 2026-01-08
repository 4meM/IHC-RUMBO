
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper para calcular rutas caminando entre dos puntos
/// Responsabilidad única: Generar polylines de rutas a pie
class WalkingRouteHelper {
  /// Genera una ruta simple caminando entre origen y destino
  /// En producción esto usaría Google Directions API
  static List<LatLng> generateSimpleWalkingRoute({
    required LatLng origin,
    required LatLng destination,
  }) {
    // Por ahora retornamos una línea recta
    // TODO: Integrar con Google Directions API para ruta real
    return [origin, destination];
  }

  /// Crea un Polyline para mostrar en el mapa
  static Polyline createWalkingPolyline({
    required String polylineId,
    required List<LatLng> points,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: Colors.blue[700]!,
      width: 4,
      patterns: [
        PatternItem.dash(20),
        PatternItem.gap(10),
      ], // Línea punteada para caminar
    );
  }

  /// Crea un marcador para el origen
  static Marker createOriginMarker({
    required LatLng position,
  }) {
    return Marker(
      markerId: MarkerId('origin'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: 'Tu ubicación'),
    );
  }

  /// Crea un marcador para el paradero destino
  static Marker createStopMarker({
    required LatLng position,
    required String stopName,
  }) {
    return Marker(
      markerId: MarkerId('stop'),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: stopName),
    );
  }

  /// Calcula los bounds para centrar el mapa en ambos puntos
  static LatLngBounds calculateBounds({
    required LatLng origin,
    required LatLng destination,
  }) {
    final double south = origin.latitude < destination.latitude
        ? origin.latitude
        : destination.latitude;
    final double north = origin.latitude > destination.latitude
        ? origin.latitude
        : destination.latitude;
    final double west = origin.longitude < destination.longitude
        ? origin.longitude
        : destination.longitude;
    final double east = origin.longitude > destination.longitude
        ? origin.longitude
        : destination.longitude;

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}
