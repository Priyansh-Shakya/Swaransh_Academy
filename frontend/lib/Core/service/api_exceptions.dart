import "package:dio/dio.dart";

/// Base class for all API-related exceptions.
/// Catch this in your repository/UI layer to handle errors generically,
/// or catch the specific subtypes below for targeted handling.
abstract class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => "$runtimeType: $message (status: $statusCode)";
}

class NetworkException extends ApiException {
  NetworkException([String message = "No internet connection. Please check your network."])
      : super(message);
}

class TimeoutApiException extends ApiException {
  TimeoutApiException([String message = "The request timed out. Please try again."])
      : super(message);
}

class BadRequestException extends ApiException {
  BadRequestException(String message, {dynamic data}) : super(message, statusCode: 400, data: data);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = "Unauthorized. Please log in again."])
      : super(message, statusCode: 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = "You don't have permission to do this."])
      : super(message, statusCode: 403);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = "Requested resource was not found."])
      : super(message, statusCode: 404);
}

class ConflictException extends ApiException {
  ConflictException([String message = "Conflict with current state of the resource."])
      : super(message, statusCode: 409);
}

class ValidationException extends ApiException {
  /// Field-level validation errors, if the backend returns them
  /// e.g. {"email": ["Email is invalid"]}
  final Map<String, dynamic>? errors;

  ValidationException(String message, {this.errors, dynamic data})
      : super(message, statusCode: 422, data: data);
}

class ServerException extends ApiException {
  ServerException([String message = "Something went wrong on the server. Please try again later."])
      : super(message, statusCode: 500);
}

class ParsingException extends ApiException {
  ParsingException([String message = "Failed to parse server response."]) : super(message);
}

class UnknownApiException extends ApiException {
  UnknownApiException([String message = "An unexpected error occurred."]) : super(message);
}

/// Central mapper: converts a DioException (or any error) into
/// one of our typed ApiExceptions. Used internally by ApiService,
/// but exported in case you want to reuse it elsewhere (e.g. interceptors).
ApiException mapDioExceptionToApiException(Object error) {
  if (error is ApiException) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutApiException();

      case DioExceptionType.connectionError:
        return NetworkException();

      case DioExceptionType.badCertificate:
        return NetworkException("Secure connection could not be established.");

      case DioExceptionType.cancel:
        return UnknownApiException("Request was cancelled.");

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        final serverMessage = _extractMessage(responseData);

        switch (statusCode) {
          case 400:
            return BadRequestException(serverMessage ?? "Bad request.", data: responseData);
          case 401:
            return UnauthorizedException(serverMessage ?? "Unauthorized. Please log in again.");
          case 403:
            return ForbiddenException(serverMessage ?? "You don't have permission to do this.");
          case 404:
            return NotFoundException(serverMessage ?? "Requested resource was not found.");
          case 409:
            return ConflictException(serverMessage ?? "Conflict with current state of the resource.");
          case 422:
            return ValidationException(
              serverMessage ?? "Validation failed.",
              errors: responseData is Map<String, dynamic> ? responseData['errors'] : null,
              data: responseData,
            );
          default:
            if (statusCode != null && statusCode >= 500) {
              return ServerException(serverMessage ?? "Something went wrong on the server.");
            }
            return UnknownApiException(serverMessage ?? "An unexpected error occurred.");
        }

      case DioExceptionType.unknown:
        return NetworkException();
    }
  }

  return UnknownApiException(error.toString());
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    return data['message'] ?? data['error'] ?? data['detail'];
  }
  return null;
}
