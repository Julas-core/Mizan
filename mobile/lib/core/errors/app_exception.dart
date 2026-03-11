sealed class AppException implements Exception {
  final String message;

  const AppException(this.message);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection failed.']);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed.']);
}

class ApiException extends AppException {
  final int statusCode;

  const ApiException(
    this.statusCode, [
    super.message = 'API returned an error.',
  ]);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'An unknown error occurred.']);
}
