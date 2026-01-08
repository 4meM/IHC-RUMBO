import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Helper para sincronizar la posición de Street View con el mapa
class StreetViewSyncHelper {
  /// Actualiza el marcador y la polyline de la ruta caminando
  /// Si el usuario se mueve en Street View, la ruta se recalcula desde la nueva posición
  static List<LatLng> updateWalkingRoute({
    required LatLng newPosition,
    required LatLng stopLocation,
  }) {
    // Por ahora, línea recta. Se puede mejorar con Directions API
    return [newPosition, stopLocation];
  }
}
