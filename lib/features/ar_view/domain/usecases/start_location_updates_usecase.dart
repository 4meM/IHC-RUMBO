import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/ar_location_repository.dart';

class StartLocationUpdatesUseCase implements UseCase<void, NoParams> {
  final ARLocationRepository repository;

  StartLocationUpdatesUseCase({required this.repository});

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.startLocationUpdates();
  }
}
