import '../../domain/entities/ar_bus_marker.dart';

class ARBusMarkerModel extends ARBusMarker {
  const ARBusMarkerModel({
    required super.busId,
    required super.busNumber,
    required super.routeName,
    required super.latitude,
    required super.longitude,
    required super.altitude,
    required super.distance,
    required super.bearing,
    required super.speed,
    required super.timestamp,
  });

  factory ARBusMarkerModel.fromJson(Map<String, dynamic> json) {
    return ARBusMarkerModel(
      busId: json['busId'] as String? ?? '',
      busNumber: json['busNumber'] as String? ?? '',
      routeName: json['routeName'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  factory ARBusMarkerModel.fromEntity(ARBusMarker entity) {
    return ARBusMarkerModel(
      busId: entity.busId,
      busNumber: entity.busNumber,
      routeName: entity.routeName,
      latitude: entity.latitude,
      longitude: entity.longitude,
      altitude: entity.altitude,
      distance: entity.distance,
      bearing: entity.bearing,
      speed: entity.speed,
      timestamp: entity.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busId': busId,
      'busNumber': busNumber,
      'routeName': routeName,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'distance': distance,
      'bearing': bearing,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
