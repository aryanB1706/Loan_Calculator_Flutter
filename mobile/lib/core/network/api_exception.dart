import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const []});

  factory ApiException.fromDio(DioException error) {
    final wrapped = error.error;
    if (wrapped is ApiException) {
      return wrapped;
    }

    final response = error.response;
    final data = response?.data;
    final statusCode = response?.statusCode;
    final backendMessage = data is Map && data['message'] is String
        ? data['message'] as String
        : null;
    final backendErrors = data is Map && data['errors'] is List
        ? data['errors'] as List
        : const [];

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'The request timed out. Please check your connection and try again.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'Could not reach the server. Check your connection and try again.',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          'A secure connection could not be established. Please try again.',
        );
      case DioExceptionType.cancel:
        return const ApiException('The request was cancelled.');
      case DioExceptionType.badResponse:
        if (statusCode != null && statusCode >= 500) {
          return ApiException(
            'Something went wrong on our side. Please try again.',
            statusCode: statusCode,
          );
        }
        if (backendMessage != null && backendMessage.isNotEmpty) {
          return ApiException(
            backendMessage,
            statusCode: statusCode,
            errors: backendErrors,
          );
        }
        return ApiException(
          _messageForStatus(statusCode),
          statusCode: statusCode,
          errors: backendErrors,
        );
      case DioExceptionType.unknown:
        return const ApiException('Something went wrong. Please try again.');
    }
  }

  final String message;
  final int? statusCode;
  final List<dynamic> errors;

  bool get isUnauthorized => statusCode == 401;

  static String _messageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Please check the information you entered and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'We could not find what you were looking for.';
      case 409:
        return 'This action conflicts with the current state. Please refresh.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Request failed. Please try again.';
    }
  }

  @override
  String toString() => message;
}
