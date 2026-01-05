import 'package:equatable/equatable.dart';

/// Entidad que representa un paradero (parada de autobús) en el dominio
class ARBusStop extends Equatable {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> routes;

  const ARBusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.routes,
  });

  @override
  List<Object?> get props => [id, name, latitude, longitude, routes];
}
