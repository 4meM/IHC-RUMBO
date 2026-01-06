import '../models/ar_bus_stop_model.dart';
import 'dart:math' as Math;

/// DataSource para obtener datos de paraderos (paradas de autobús)
abstract class ARBusStopsDataSource {
  /// Obtiene una lista de paraderos cercanos a la ubicación del usuario
  Future<List<ARBusStopModel>> getNearbyBusStops(
    double userLat,
    double userLng,
    double radiusInMeters,
  );

  /// Obtiene todos los paraderos de Arequipa
  Future<List<ARBusStopModel>> getAllBusStops();

  /// Obtiene el paradero más cercano a la ubicación del usuario
  Future<ARBusStopModel?> getNearestBusStop(
    double userLat,
    double userLng,
  );
}

/// Implementación con datos reales de Arequipa
class ARBusStopsDataSourceImpl implements ARBusStopsDataSource {
  /// Paraderos reales de Arequipa con sus coordenadas
  static final List<ARBusStopModel> _allBusStops = [
    // Centro Histórico - Plaza de Armas
    ARBusStopModel(
      id: 'stop_001',
      name: 'Plaza de Armas',
      latitude: -16.3994,
      longitude: -71.5350,
      routes: ['1', '2', '3', '4', '5'],
    ),
    // Cercado - Calle San Juan de Dios
    ARBusStopModel(
      id: 'stop_002',
      name: 'San Juan de Dios',
      latitude: -16.4006,
      longitude: -71.5368,
      routes: ['2', '6', '7'],
    ),
    // Yanahuara
    ARBusStopModel(
      id: 'stop_003',
      name: 'Yanahuara',
      latitude: -16.3889,
      longitude: -71.5500,
      routes: ['8', '9', '10'],
    ),
    // Selina
    ARBusStopModel(
      id: 'stop_004',
      name: 'Selina',
      latitude: -16.4156,
      longitude: -71.5268,
      routes: ['11', '12'],
    ),
    // Paucarpata
    ARBusStopModel(
      id: 'stop_005',
      name: 'Paucarpata',
      latitude: -16.4389,
      longitude: -71.5389,
      routes: ['13', '14', '15'],
    ),
    // Cayma
    ARBusStopModel(
      id: 'stop_006',
      name: 'Cayma',
      latitude: -16.3556,
      longitude: -71.5389,
      routes: ['16', '17'],
    ),
    // Agua Santa
    ARBusStopModel(
      id: 'stop_007',
      name: 'Agua Santa',
      latitude: -16.4022,
      longitude: -71.5606,
      routes: ['18', '19', '20'],
    ),
    // Alto Selina
    ARBusStopModel(
      id: 'stop_008',
      name: 'Alto Selina',
      latitude: -16.4289,
      longitude: -71.5078,
      routes: ['21', '22'],
    ),
    // Sachaca
    ARBusStopModel(
      id: 'stop_009',
      name: 'Sachaca',
      latitude: -16.3722,
      longitude: -71.4867,
      routes: ['23', '24', '25'],
    ),
    // Mariano Melgar
    ARBusStopModel(
      id: 'stop_010',
      name: 'Mariano Melgar',
      latitude: -16.4667,
      longitude: -71.4933,
      routes: ['26', '27'],
    ),
    // Paradero cercano a ubicación del usuario
    ARBusStopModel(
      id: 'stop_011',
      name: 'Paradero Principal',
      latitude: -16.310628,
      longitude: -71.611743,
      routes: ['1', '2', '3', '5', '8', '12'],
    ),
    // Paradero de prueba para testing AR
    ARBusStopModel(
      id: 'stop_012',
      name: 'Paradero Test AR',
      latitude: -16.311653,
      longitude: -71.612231,
      routes: ['1', '5', '8'],
    ),
  ];

  @override
  Future<List<ARBusStopModel>> getNearbyBusStops(
    double userLat,
    double userLng,
    double radiusInMeters,
  ) async {
    // Simulación de delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    return _allBusStops
        .where((stop) {
          final distance = _calculateDistance(
            userLat,
            userLng,
            stop.latitude,
            stop.longitude,
          );
          return distance <= radiusInMeters;
        })
        .toList();
  }

  @override
  Future<List<ARBusStopModel>> getAllBusStops() async {
    // Simulación de delay de red
    await Future.delayed(const Duration(milliseconds: 300));
    return _allBusStops;
  }

  @override
  Future<ARBusStopModel?> getNearestBusStop(
    double userLat,
    double userLng,
  ) async {
    // Simulación de delay de red
    await Future.delayed(const Duration(milliseconds: 300));

    if (_allBusStops.isEmpty) return null;

    ARBusStopModel? nearest;
    double minDistance = double.infinity;

    for (final stop in _allBusStops) {
      final distance = _calculateDistance(
        userLat,
        userLng,
        stop.latitude,
        stop.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = stop;
      }
    }

    return nearest;
  }

  /// Calcula la distancia entre dos puntos usando la fórmula de Haversine
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);

    final a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_degreesToRadians(lat1)) *
            Math.cos(_degreesToRadians(lat2)) *
            Math.sin(dLng / 2) *
            Math.sin(dLng / 2));

    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c * 1000; // Convertir a metros
  }

  /// Convierte grados a radianes
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
}

// Importar Math para funciones trigonométricas

