part of 'ar_view_bloc.dart';

abstract class ARViewEvent extends Equatable {
  const ARViewEvent();

  @override
  List<Object?> get props => [];
}

class InitializeARViewEvent extends ARViewEvent {
  const InitializeARViewEvent();
}

class UpdateUserLocationEvent extends ARViewEvent {
  final dynamic locationResult; // Either<Failure, ARUserLocation>

  const UpdateUserLocationEvent(this.locationResult);

  @override
  List<Object?> get props => [locationResult];
}

class UpdateNearbyBusesEvent extends ARViewEvent {
  final double userLat;
  final double userLng;

  const UpdateNearbyBusesEvent({
    required this.userLat,
    required this.userLng,
  });

  @override
  List<Object?> get props => [userLat, userLng];
}

class StopARViewEvent extends ARViewEvent {
  const StopARViewEvent();
}
