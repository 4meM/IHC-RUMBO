import 'package:equatable/equatable.dart';

class ARBusMarker extends Equatable {
  final String busId;
  final String busNumber;
  final String routeName;
  final double latitude;
  final double longitude;
  final double altitude;
  final double distance; // distancia en metros
  final double bearing; // dirección en grados
  final double speed; // velocidad en km/h
  final DateTime timestamp;

  const ARBusMarker({
    required this.busId,
    required this.busNumber,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.distance,
    required this.bearing,
    required this.speed,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    busId,
    busNumber,
    routeName,
    latitude,
    longitude,
    altitude,
    distance,
    bearing,
    speed,
    timestamp,
  ];
}
