class RouterException implements Exception {
  final String message;
  final String? code;

  RouterException(this.message, [this.code]);

  @override
  String toString() =>
      'RouterException: $message ${code != null ? '($code)' : ''}';
}

class DatabaseException extends RouterException {
  DatabaseException(String message) : super(message, 'DB_ERROR');
}

class RouterNotFoundException extends RouterException {
  RouterNotFoundException()
    : super('Router not found in database', 'NOT_FOUND');
}

class MikrotikConnectionException extends RouterException {
  MikrotikConnectionException(String message)
    : super(message, 'CONNECTION_ERROR');
}

class MikrotikAuthException extends RouterException {
  MikrotikAuthException([String message = 'Invalid username or password'])
    : super(message, 'AUTH_ERROR');
}

class MikrotikException extends RouterException {
  MikrotikException(String message, [String? code])
    : super(message, code ?? 'MIKROTIK_ERROR');
}
