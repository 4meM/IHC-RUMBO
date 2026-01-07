import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ============================================
/// TRACKING MARKER HELPER
/// Funciones puras para crear marcadores de tracking
/// Estilo: Programación Competitiva
/// ============================================

/// Crear marcador de ubicación del usuario
/// Input: posición actual
/// Output: Marker configurado
Marker createUserLocationMarker(LatLng position) {
  return Marker(
    markerId: const MarkerId('user_location'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    infoWindow: const InfoWindow(title: 'Tu ubicación'),
  );
}

/// Crear marcador de ubicación del bus en tiempo real
/// Input: posición del bus, número de bus
/// Output: Marker configurado
Marker createBusLocationMarker(LatLng position, String busNumber) {
  return Marker(
    markerId: const MarkerId('bus_location'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    infoWindow: InfoWindow(title: 'Bus $busNumber'),
  );
}

/// Crear marcador de destino final (ROJO)
/// Input: posición del destino
/// Output: Marker configurado
Marker createDestinationMarker(LatLng position) {
  return Marker(
    markerId: const MarkerId('destination'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    infoWindow: const InfoWindow(title: 'Destino'),
  );
}

/// Crear marcador de origen (VERDE)
/// Input: posición del origen
/// Output: Marker configurado
Marker createOriginMarkerForTracking(LatLng position) {
  return Marker(
    markerId: const MarkerId('origin'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    infoWindow: const InfoWindow(title: 'Origen'),
  );
}

/// Crear marcador de paradero de subida (AMARILLO)
/// Input: posición del pickup
/// Output: Marker configurado
Marker createPickupMarkerForTracking(LatLng position) {
  return Marker(
    markerId: const MarkerId('pickup'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    infoWindow: const InfoWindow(title: 'Paradero de subida'),
  );
}

/// Crear marcador de paradero de bajada (AMARILLO)
/// Input: posición del dropoff
/// Output: Marker configurado
Marker createDropoffMarkerForTracking(LatLng position) {
  return Marker(
    markerId: const MarkerId('dropoff'),
    position: position,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    infoWindow: const InfoWindow(title: 'Paradero de bajada'),
  );
}

/// Crear set completo de marcadores para tracking
/// Input: posición usuario, posición bus, origen, destino, pickup, dropoff, número de bus
/// Output: Set de marcadores
Set<Marker> createTrackingMarkers({
  required LatLng userPosition,
  required LatLng busPosition,
  required LatLng origin,
  required LatLng destination,
  required String busNumber,
  LatLng? pickupPoint,
  LatLng? dropoffPoint,
}) {
  final markers = {
    createUserLocationMarker(userPosition),
    createBusLocationMarker(busPosition, busNumber),
    createOriginMarkerForTracking(origin),
    createDestinationMarker(destination),
  };
  
  // Agregar marcadores de paraderos si existen
  if (pickupPoint != null) {
    markers.add(createPickupMarkerForTracking(pickupPoint));
  }
  if (dropoffPoint != null) {
    markers.add(createDropoffMarkerForTracking(dropoffPoint));
  }
  
  return markers;
}

/// Actualizar solo la posición del bus en el set de marcadores
/// Input: marcadores actuales, nueva posición del bus, número de bus
/// Output: Set de marcadores actualizado
Set<Marker> updateBusMarkerPosition(
  Set<Marker> currentMarkers,
  LatLng newBusPosition,
  String busNumber,
) {
  final updatedMarkers = currentMarkers
      .where((marker) => marker.markerId.value != 'bus_location')
      .toSet();
  
  updatedMarkers.add(createBusLocationMarker(newBusPosition, busNumber));
  
  return updatedMarkers;
}
