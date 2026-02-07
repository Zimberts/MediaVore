/// Base class for all application exceptions.
abstract class AppException implements Exception {
  final String message;
  final dynamic cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Exception thrown when there's a server error (4xx or 5xx status codes).
class ServerException extends AppException {
  final int? statusCode;

  const ServerException(super.message, [this.statusCode, super.cause]);
}

/// Exception thrown when there's a network connectivity issue.
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// Exception thrown when the API response format is unexpected.
class ParsingException extends AppException {
  const ParsingException(super.message, [super.cause]);
}

/// Exception thrown when required configuration (like API keys) is missing.
class ConfigurationException extends AppException {
  const ConfigurationException(super.message, [super.cause]);
}
