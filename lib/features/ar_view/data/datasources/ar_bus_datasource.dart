import '../models/ar_bus_marker_model.dart';

abstract class ARBusDataSource {
  /// Obtiene los autobuses cercanos en tiempo real
  /// basados en la ubicación del usuario
  Future<List<ARBusMarkerModel>> getNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  );

  /// Monitorea los autobuses cercanos
  Stream<List<ARBusMarkerModel>> monitorNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  );
}

class ARBusDataSourceImpl implements ARBusDataSource {
  // En una implementación real, esto vendría de un API o WebSocket
  // Por ahora usamos datos mock

  @override
  Future<List<ARBusMarkerModel>> getNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  ) async {
    // Simular latencia de API
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      ARBusMarkerModel(
        busId: 'bus_001',
        busNumber: '12',
        routeName: 'Centro - Cercado',
        latitude: userLat + 0.001,
        longitude: userLng + 0.001,
        altitude: 2300.0,
        distance: 150.0,
        bearing: 45.0,
        speed: 35.0,
        timestamp: DateTime.now(),
      ),
      ARBusMarkerModel(
        busId: 'bus_002',
        busNumber: '5',
        routeName: 'Yanahuara - Cercado',
        latitude: userLat - 0.002,
        longitude: userLng + 0.0015,
        altitude: 2300.0,
        distance: 250.0,
        bearing: 120.0,
        speed: 28.0,
        timestamp: DateTime.now(),
      ),
      ARBusMarkerModel(
        busId: 'bus_003',
        busNumber: '8',
        routeName: 'Jacobo - Cercado',
        latitude: userLat + 0.0015,
        longitude: userLng - 0.001,
        altitude: 2300.0,
        distance: 320.0,
        bearing: 270.0,
        speed: 40.0,
        timestamp: DateTime.now(),
      ),
    ];
  }

  @override
  Stream<List<ARBusMarkerModel>> monitorNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  ) {
    return Stream.periodic(
      const Duration(seconds: 2),
      (_) => _generateRandomBuses(userLat, userLng),
    ).asyncMap((_) => getNearbyBuses(userLat, userLng, radiusMeters));
  }

  List<ARBusMarkerModel> _generateRandomBuses(double userLat, double userLng) {
    // Aquí iría la lógica para variar las posiciones de los buses
    return [];
  }
}
