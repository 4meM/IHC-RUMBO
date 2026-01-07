import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Crear un marcador de origen (verde) para el mapa
/// Input: posición del marcador
/// Output: Marker configurado como punto de origen
Marker createOriginMarker(LatLng position) {
  return Marker(
    markerId: const MarkerId('origin'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    infoWindow: const InfoWindow(title: 'Origen'),
  );
}

/// Crear un marcador de destino (rojo) para el mapa
/// Input: posición del marcador
/// Output: Marker configurado como punto de destino
Marker createDestinationMarker(LatLng position) {
  return Marker(
    markerId: const MarkerId('destination'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    infoWindow: const InfoWindow(title: 'Destino'),
  );
}

/// Crear un marcador de pickup (azul) - punto de subida al bus
/// Input: posición del marcador
/// Output: Marker configurado como punto de recogida
Marker createPickupMarker(LatLng position) {
  return Marker(
    markerId: const MarkerId('pickup'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    infoWindow: const InfoWindow(title: 'Subida'),
  );
}

/// Crear un marcador de dropoff (amarillo) - punto de bajada del bus
/// Input: posición del marcador
/// Output: Marker configurado como punto de bajada
Marker createDropoffMarker(LatLng position) {
  return Marker(
    markerId: const MarkerId('dropoff'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    infoWindow: const InfoWindow(title: 'Bajada'),
  );
}

/// Crear un set de marcadores con origen y destino
/// Input: posición origen, posición destino
/// Output: Set con ambos marcadores
Set<Marker> createOriginDestinationMarkers(LatLng origin, LatLng destination) {
  return {
    createOriginMarker(origin),
    createDestinationMarker(destination),
  };
}

/// Crear un set completo de marcadores para una ruta (origen, destino, pickup, dropoff)
/// Input: todas las posiciones necesarias
/// Output: Set con los 4 marcadores
Set<Marker> createCompleteRouteMarkers({
  required LatLng origin,
  required LatLng destination,
  required LatLng pickup,
  required LatLng dropoff,
}) {
  return {
    createOriginMarker(origin),
    createDestinationMarker(destination),
    createPickupMarker(pickup),
    createDropoffMarker(dropoff),
  };
}

/// Crear un marcador genérico con ID y color personalizados
/// Input: ID único, posición, color (hue), título opcional
/// Output: Marker personalizado
Marker createCustomMarker({
  required String id,
  required LatLng position,
  required double hue,
  String? title,
}) {
  return Marker(
    markerId: MarkerId(id),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(hue),
    infoWindow: InfoWindow(title: title),
  );
}

/// Crear múltiples marcadores de bus en el mapa
/// Input: mapa de ID -> posición de buses
/// Output: Set de marcadores de buses
Set<Marker> createBusMarkers(Map<String, LatLng> busPositions) {
  return busPositions.entries.map((entry) {
    return Marker(
      markerId: MarkerId('bus_${entry.key}'),
      position: entry.value,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(title: 'Bus ${entry.key}'),
    );
  }).toSet();
}
