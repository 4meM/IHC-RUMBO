import 'package:equatable/equatable.dart';

/// Clase base abstracta para todos los errores en la aplicación
/// Usa Equatable para comparar fallos por su contenido
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// --- Fallos del Servidor ---
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error del servidor']) : super(message);
}

// --- Fallos de Caché/Storage ---
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Error de almacenamiento local']) : super(message);
}

// --- Fallos de Red ---
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Sin conexión a internet']) : super(message);
}

// --- Fallos de Autenticación ---
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Error de autenticación']) : super(message);
}

// --- Fallos de Validación ---
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Datos inválidos']) : super(message);
}
