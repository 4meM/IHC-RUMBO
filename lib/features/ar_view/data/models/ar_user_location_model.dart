import '../../domain/entities/ar_user_location.dart';

class ARUserLocationModel extends ARUserLocation {
  const ARUserLocationModel({
    required super.latitude,
    required super.longitude,
    required super.altitude,
    required super.accuracy,
    required super.heading,
    required super.timestamp,
  });

  factory ARUserLocationModel.fromJson(Map<String, dynamic> json) {
    return ARUserLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  factory ARUserLocationModel.fromEntity(ARUserLocation entity) {
    return ARUserLocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      altitude: entity.altitude,
      accuracy: entity.accuracy,
      heading: entity.heading,
      timestamp: entity.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
