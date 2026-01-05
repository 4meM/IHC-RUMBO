import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ar_bus_marker.dart';
import '../../domain/entities/ar_bus_stop.dart';
import '../../domain/repositories/ar_bus_repository.dart';
import '../datasources/ar_bus_datasource.dart';
import '../datasources/ar_bus_stops_datasource.dart';

class ARBusRepositoryImpl implements ARBusRepository {
  final ARBusDataSource dataSource;
  final ARBusStopsDataSource busStopsDataSource;

  ARBusRepositoryImpl({
    required this.dataSource,
    required this.busStopsDataSource,
  });

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

  @override
  Future<Either<Failure, ARBusStop?>> getNearestBusStop(
    double userLat,
    double userLng,
  ) async {
    try {
      final nearestStopModel = await busStopsDataSource.getNearestBusStop(
        userLat,
        userLng,
      );
      final nearestStop = nearestStopModel?.toEntity();
      return Right(nearestStop);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
