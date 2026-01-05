import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ar_user_location.dart';
import '../repositories/ar_location_repository.dart';

abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

class GetUserLocationStream implements StreamUseCase<ARUserLocation, NoParams> {
  final ARLocationRepository repository;

  GetUserLocationStream({required this.repository});

  @override
  Stream<Either<Failure, ARUserLocation>> call(NoParams params) {
    return repository.getUserLocationStream();
  }
}
