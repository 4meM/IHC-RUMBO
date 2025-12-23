import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

/// Clase base para todos los casos de uso de la aplicación
/// 
/// [Type] - El tipo de dato que retorna el caso de uso
/// [Params] - Los parámetros que recibe el caso de uso
/// 
/// Retorna un Either<Failure, Type>:
/// - Left(Failure): Cuando ocurre un error
/// - Right(Type): Cuando la operación es exitosa
/// 
/// Ejemplo de uso:
/// ```dart
/// class LoginUseCase implements UseCase<UserEntity, LoginParams> {
///   @override
///   Future<Either<Failure, UserEntity>> call(LoginParams params) async {
///     // Implementación
///   }
/// }
/// ```
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// UseCase sin parámetros
class NoParams {
  const NoParams();
}
