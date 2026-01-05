import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ar_bus_marker.dart';
import '../repositories/ar_bus_repository.dart';

abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

class GetNearbyBusesUseCase implements StreamUseCase<List<ARBusMarker>, GetNearbyBusesParams> {
  final ARBusRepository repository;

  GetNearbyBusesUseCase({required this.repository});

  @override
  Stream<Either<Failure, List<ARBusMarker>>> call(GetNearbyBusesParams params) {
    return repository.monitorNearbyBuses(
      params.userLat,
      params.userLng,
      params.radiusMeters,
    );
  }
}

class GetNearbyBusesParams extends Equatable {
  final double userLat;
  final double userLng;
  final double radiusMeters;

  const GetNearbyBusesParams({
    required this.userLat,
    required this.userLng,
    required this.radiusMeters,
  });

  @override
  List<Object?> get props => [userLat, userLng, radiusMeters];
}
