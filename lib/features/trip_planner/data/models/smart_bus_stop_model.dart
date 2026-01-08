import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Tipos de paradas inteligentes
enum SmartStopType {
  nearest, // El más cercano
  avoidTraffic, // Evita tráfico
  guaranteedSeats; // Garantiza asientos

  String get displayName {
    switch (this) {
      case SmartStopType.nearest:
        return 'El Más Cercano';
      case SmartStopType.avoidTraffic:
        return 'Evita Tráfico';
      case SmartStopType.guaranteedSeats:
        return 'Asientos Garantizados';
    }
  }

  String get description {
    switch (this) {
      case SmartStopType.nearest:
        return 'A solo unos pasos';
      case SmartStopType.avoidTraffic:
        return 'Menos congestión';
      case SmartStopType.guaranteedSeats:
        return 'Más probabilidad de sentarse';
    }
  }

  String get emoji {
    switch (this) {
      case SmartStopType.nearest:
        return '📍';
      case SmartStopType.avoidTraffic:
        return '🚗';
      case SmartStopType.guaranteedSeats:
        return '🪑';
    }
  }
}

/// Modelo de parada inteligente
class SmartBusStopModel {
  final String id;
  final String name;
  final LatLng location;
  final SmartStopType type;
  final double walkingDistance; // en metros
  final double estimatedBusDistance; // en metros
  final int estimatedWaitTime; // en minutos
  final int estimatedTravelTime; // en minutos
  final double crowdLevel; // 0.0 a 1.0 (0 = vacío, 1 = lleno)
  final int estimatedAvailableSeats;
  final String reason; // Por qué esta parada es recomendada
  final List<String> routes; // Rutas que pasan por aquí

  SmartBusStopModel({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.walkingDistance,
    required this.estimatedBusDistance,
    required this.estimatedWaitTime,
    required this.estimatedTravelTime,
    required this.crowdLevel,
    required this.estimatedAvailableSeats,
    required this.reason,
    required this.routes,
  });

  /// Distancia total (caminata + bus)
  double get totalDistance => walkingDistance + estimatedBusDistance;

  /// Tiempo total (espera + viaje)
  int get totalTime => estimatedWaitTime + estimatedTravelTime;

  /// Score de conveniencia (menor es mejor)
  double get convenienceScore {
    // Factor de distancia (40%)
    final distanceFactor = walkingDistance / 1000; // convertir a km

    // Factor de tiempo (30%)
    final timeFactor = totalTime / 30; // normalizar a 30 min

    // Factor de congestión (20%)
    final crowdFactor = crowdLevel;

    // Factor de asientos (10%)
    final seatsFactor = (10 - estimatedAvailableSeats) / 10;

    return (distanceFactor * 0.4) + (timeFactor * 0.3) + (crowdFactor * 0.2) + (seatsFactor * 0.1);
  }

  @override
  String toString() => '$name (${type.displayName})';

  /// Convierte a JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'type': type.name,
        'walkingDistance': walkingDistance,
        'estimatedBusDistance': estimatedBusDistance,
        'estimatedWaitTime': estimatedWaitTime,
        'estimatedTravelTime': estimatedTravelTime,
        'crowdLevel': crowdLevel,
        'estimatedAvailableSeats': estimatedAvailableSeats,
        'reason': reason,
        'routes': routes,
      };
}
