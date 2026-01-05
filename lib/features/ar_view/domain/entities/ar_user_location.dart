import 'package:equatable/equatable.dart';

class ARUserLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double heading;
  final DateTime timestamp;

  const ARUserLocation({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.heading,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    altitude,
    accuracy,
    heading,
    timestamp,
  ];
}
