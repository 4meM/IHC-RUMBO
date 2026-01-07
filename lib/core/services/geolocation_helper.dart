import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Verificar si el servicio de GPS está habilitado en el dispositivo
/// Input: ninguno
/// Output: true si GPS está activo, false si no
Future<bool> isGPSEnabled() async {
  return await Geolocator.isLocationServiceEnabled();
}

/// Verificar el estado actual de los permisos de ubicación
/// Input: ninguno
/// Output: LocationPermission actual
Future<LocationPermission> checkLocationPermission() async {
  return await Geolocator.checkPermission();
}

/// Solicitar permisos de ubicación al usuario
/// Input: ninguno
/// Output: LocationPermission después de la solicitud
Future<LocationPermission> requestLocationPermission() async {
  return await Geolocator.requestPermission();
}

/// Obtener la posición actual del dispositivo
/// Input: ninguno
/// Output: Position con lat, lng, accuracy, etc.
Future<Position> getCurrentPosition() async {
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
    timeLimit: const Duration(seconds: 10),
  );
}

/// Convertir Position de geolocator a LatLng de Google Maps
/// Input: Position
/// Output: LatLng
LatLng positionToLatLng(Position position) {
  return LatLng(position.latitude, position.longitude);
}

/// Obtener posición actual y convertirla directamente a LatLng
/// Input: ninguno
/// Output: LatLng con la ubicación actual
Future<LatLng> getCurrentLatLng() async {
  final position = await getCurrentPosition();
  return positionToLatLng(position);
}

/// Verificar y solicitar permisos si es necesario
/// Input: ninguno
/// Output: true si permisos concedidos, false si denegados
Future<bool> ensureLocationPermissions() async {
  LocationPermission permission = await checkLocationPermission();
  
  if (permission == LocationPermission.denied) {
    permission = await requestLocationPermission();
  }
  
  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}

/// Validar que GPS esté activo y permisos concedidos
/// Input: ninguno
/// Output: mensaje de error si hay problema, null si todo OK
Future<String?> validateLocationServices() async {
  final gpsEnabled = await isGPSEnabled();
  
  if (!gpsEnabled) {
    return 'GPS desactivado. Por favor activa la ubicación en tu dispositivo.';
  }
  
  final permission = await checkLocationPermission();
  
  if (permission == LocationPermission.deniedForever) {
    return 'Permisos de ubicación denegados permanentemente. Ve a Configuración.';
  }
  
  if (permission == LocationPermission.denied) {
    final newPermission = await requestLocationPermission();
    if (newPermission == LocationPermission.denied) {
      return 'Permisos de ubicación denegados. La app necesita acceso.';
    }
  }
  
  return null; // Todo OK
}

/// Obtener ubicación con manejo completo de errores
/// Input: ninguno
/// Output: Result con LatLng o mensaje de error
Future<({LatLng? location, String? error})> getLocationSafely() async {
  try {
    final errorMessage = await validateLocationServices();
    if (errorMessage != null) {
      return (location: null, error: errorMessage);
    }
    
    final position = await getCurrentPosition();
    return (
      location: positionToLatLng(position),
      error: null,
    );
  } catch (e) {
    return (
      location: null,
      error: 'Error al obtener ubicación: ${e.toString()}',
    );
  }
}

/// Crear un stream de actualizaciones de posición
/// Input: ninguno
/// Output: Stream de Position
Stream<Position> getPositionStream() {
  return Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    ),
  );
}

/// Convertir stream de Position a stream de LatLng
/// Input: ninguno
/// Output: Stream de LatLng
Stream<LatLng> getLatLngStream() {
  return getPositionStream().map((position) => positionToLatLng(position));
}
