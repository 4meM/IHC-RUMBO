import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ar_user_location.dart';
import '../../domain/repositories/ar_location_repository.dart';
import '../datasources/ar_location_datasource.dart';

class ARLocationRepositoryImpl implements ARLocationRepository {
  final ARLocationDataSource dataSource;

  ARLocationRepositoryImpl({required this.dataSource});

  @override
  Stream<Either<Failure, ARUserLocation>> getUserLocationStream() async* {
    try {
      yield* dataSource.getUserLocationStream().map(
        (location) => Right<Failure, ARUserLocation>(location),
      );
    } catch (e) {
      yield Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkAndRequestPermissions() async {
    try {
      final result = await dataSource.checkAndRequestPermissions();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startLocationUpdates() async {
    try {
      await dataSource.startLocationUpdates();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopLocationUpdates() async {
    try {
      await dataSource.stopLocationUpdates();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
