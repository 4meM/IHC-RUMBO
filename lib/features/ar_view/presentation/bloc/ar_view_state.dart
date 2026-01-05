part of 'ar_view_bloc.dart';

abstract class ARViewState extends Equatable {
  const ARViewState();

  @override
  List<Object?> get props => [];
}

class ARViewInitial extends ARViewState {
  const ARViewInitial();
}

class ARViewLoading extends ARViewState {
  const ARViewLoading();
}

class ARViewReady extends ARViewState {
  final ARUserLocation? userLocation;
  final List<ARBusMarker> nearbyBuses;

  const ARViewReady({
    required this.userLocation,
    required this.nearbyBuses,
  });

  @override
  List<Object?> get props => [userLocation, nearbyBuses];
}

class ARViewError extends ARViewState {
  final String message;

  const ARViewError(this.message);

  @override
  List<Object?> get props => [message];
}
