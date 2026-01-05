import 'package:equatable/equatable.dart';
import '../../domain/entities/ar_bus_stop.dart';

/// Modelo de paradero (parada de autobús) para la capa de datos
class ARBusStopModel extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> routes;

  const ARBusStopModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.routes,
  });

  /// Convierte el modelo a entidad de dominio
  ARBusStop toEntity() {
    return ARBusStop(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      routes: routes,
    );
  }

  /// Crea un modelo desde JSON
  factory ARBusStopModel.fromJson(Map<String, dynamic> json) {
    return ARBusStopModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      routes: List<String>.from(json['routes'] as List? ?? []),
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'routes': routes,
    };
  }

  @override
  List<Object?> get props => [id, name, latitude, longitude, routes];
}
