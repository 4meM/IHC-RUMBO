import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ar_bus_marker.dart';
import '../../domain/repositories/ar_bus_repository.dart';
import '../datasources/ar_bus_datasource.dart';

class ARBusRepositoryImpl implements ARBusRepository {
  final ARBusDataSource dataSource;

  ARBusRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<ARBusMarker>>> getNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  ) async {
    try {
      final buses = await dataSource.getNearbyBuses(
        userLat,
        userLng,
        radiusMeters,
      );
      return Right(buses);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<ARBusMarker>>> monitorNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  ) async* {
    try {
      yield* dataSource
          .monitorNearbyBuses(userLat, userLng, radiusMeters)
          .map((buses) => Right<Failure, List<ARBusMarker>>(buses));
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }
}
