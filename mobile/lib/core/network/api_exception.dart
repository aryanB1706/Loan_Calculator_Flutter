import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors = const []});

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map) {
      final message = data['message'];
      final errors = data['errors'];

      return ApiException(
        message is String && message.isNotEmpty ? message : 'Request failed',
        statusCode: response?.statusCode,
        errors: errors is List ? errors : const [],
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const ApiException(
          'Could not reach the server. Check your connection and try again.',
        );
      default:
        return ApiException(error.message ?? 'Something went wrong.');
    }
  }

  final String message;
  final int? statusCode;
  final List<dynamic> errors;

  @override
  String toString() => message;
}
