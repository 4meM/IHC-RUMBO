import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ar_location_repository.dart';

class CheckAndRequestLocationPermissions implements UseCase<bool, NoParams> {
  final ARLocationRepository repository;

  CheckAndRequestLocationPermissions({required this.repository});

  @override
  Future<Either<Failure, bool>> call(NoParams params) {
    return repository.checkAndRequestPermissions();
  }
}
