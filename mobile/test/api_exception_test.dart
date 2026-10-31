import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loan_app/core/network/api_exception.dart';

void main() {
  test('uses the backend message for validation errors', () {
    final options = RequestOptions(path: '/auth/verify-otp');
    final error = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 400,
        data: {
          'success': false,
          'message': 'Invalid OTP',
          'errors': [
            {'field': 'attemptsRemaining', 'message': '2'},
          ],
        },
      ),
    );

    final exception = ApiException.fromDio(error);

    expect(exception.message, 'Invalid OTP');
    expect(exception.statusCode, 400);
    expect(exception.errors, hasLength(1));
  });

  test('hides internal server errors behind a friendly message', () {
    final options = RequestOptions(path: '/loans');
    final error = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 500,
        data: {'success': false, 'message': 'MongoServerError: timeout'},
      ),
    );

    expect(
      ApiException.fromDio(error).message,
      'Something went wrong on our side. Please try again.',
    );
  });

  test('maps timeouts to a friendly message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/loans'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(
      ApiException.fromDio(error).message,
      'The request timed out. Please check your connection and try again.',
    );
  });

  test('keeps a wrapped ApiException unchanged', () {
    const original = ApiException(
      'Your session has expired. Please sign in again.',
      statusCode: 401,
    );
    final error = DioException(
      requestOptions: RequestOptions(path: '/loans'),
      error: original,
    );

    expect(identical(ApiException.fromDio(error), original), isTrue);
  });
}
