import 'package:equatable/equatable.dart';

/// Entidad de ubicación
/// Representa un punto geográfico en la aplicación
class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  List<Object?> get props => [latitude, longitude, address];

  @override
  String toString() => 'Location($latitude, $longitude)';
}
