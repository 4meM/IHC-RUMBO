import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ar_bus_marker.dart';
import '../entities/ar_bus_stop.dart';

abstract class ARBusRepository {
  Future<Either<Failure, List<ARBusMarker>>> getNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  );

  Stream<Either<Failure, List<ARBusMarker>>> monitorNearbyBuses(
    double userLat,
    double userLng,
    double radiusMeters,
  );

  Future<Either<Failure, ARBusStop?>> getNearestBusStop(
    double userLat,
    double userLng,
  );
}
