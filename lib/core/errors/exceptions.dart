/// Excepción lanzada cuando hay un error del servidor
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Error del servidor']);

  @override
  String toString() => 'ServerException: $message';
}

/// Excepción lanzada cuando hay un error de caché
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Error de caché']);

  @override
  String toString() => 'CacheException: $message';
}

/// Excepción lanzada cuando no hay conexión a internet
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Sin conexión a internet']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Excepción lanzada cuando hay un error de autenticación
class AuthenticationException implements Exception {
  final String message;
  const AuthenticationException([this.message = 'Error de autenticación']);

  @override
  String toString() => 'AuthenticationException: $message';
}
