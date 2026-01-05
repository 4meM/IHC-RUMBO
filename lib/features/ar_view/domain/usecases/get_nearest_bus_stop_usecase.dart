import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ar_bus_stop.dart';
import '../repositories/ar_bus_repository.dart';

class GetNearestBusStopUseCase implements UseCase<ARBusStop?, GetNearestBusStopParams> {
  final ARBusRepository repository;

  GetNearestBusStopUseCase({required this.repository});

  @override
  Future<Either<Failure, ARBusStop?>> call(GetNearestBusStopParams params) {
    return repository.getNearestBusStop(
      params.userLat,
      params.userLng,
    );
  }
}

class GetNearestBusStopParams extends Equatable {
  final double userLat;
  final double userLng;

  const GetNearestBusStopParams({
    required this.userLat,
    required this.userLng,
  });

  @override
  List<Object?> get props => [userLat, userLng];
}
