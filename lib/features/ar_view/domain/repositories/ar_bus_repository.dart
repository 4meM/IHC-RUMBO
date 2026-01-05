import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ar_bus_marker.dart';

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
}
