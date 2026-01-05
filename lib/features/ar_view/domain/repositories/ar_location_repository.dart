import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ar_user_location.dart';

abstract class ARLocationRepository {
  Stream<Either<Failure, ARUserLocation>> getUserLocationStream();
  Future<Either<Failure, bool>> checkAndRequestPermissions();
  Future<Either<Failure, void>> startLocationUpdates();
  Future<Either<Failure, void>> stopLocationUpdates();
}
