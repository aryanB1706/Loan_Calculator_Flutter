import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;

import '../../routes/app_routes.dart';
import '../config/app_config.dart';
import '../storage/session_service.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'debug_log_interceptor.dart';

class ApiClient {
  ApiClient(this._session, {Dio? dio, Dio? refreshDio})
    : _dio = dio ?? Dio(_options()),
      _refreshDio = refreshDio ?? Dio(_options()) {
    if (kDebugMode) {
      _dio.interceptors.add(DebugLogInterceptor());
      _refreshDio.interceptors.add(DebugLogInterceptor());
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _session.readAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final isRefreshRequest = error.requestOptions.path.contains(
            '/auth/refresh',
          );
          final alreadyRetried =
              error.requestOptions.extra[_retriedKey] == true;

          if (statusCode != 401 || isRefreshRequest) {
            handler.next(error);
            return;
          }

          if (alreadyRetried) {
            await _handleSessionExpired();
            handler.next(_sessionExpiredError(error.requestOptions));
            return;
          }

          final refreshed = await _refreshSession();
          if (!refreshed) {
            await _handleSessionExpired();
            handler.next(_sessionExpiredError(error.requestOptions));
            return;
          }

          try {
            final requestOptions = error.requestOptions;
            requestOptions.extra[_retriedKey] = true;

            final accessToken = await _session.readAccessToken();
            if (accessToken != null && accessToken.isNotEmpty) {
              requestOptions.headers['Authorization'] = 'Bearer $accessToken';
            }

            final response = await _dio.fetch<Map<String, dynamic>>(
              requestOptions,
            );
            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          }
        },
      ),
    );
  }

  static const String _retriedKey = 'auth_retried';
  static const String _refreshPath = '/auth/refresh';

  final Dio _dio;
  final Dio _refreshDio;
  final SessionService _session;
  Future<bool>? _refreshFuture;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Object? data)? parser,
  }) {
    return _execute(
      () => _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      ),
      parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    T Function(Object? data)? parser,
  }) {
    return _execute(
      () => _dio.post<Map<String, dynamic>>(path, data: data),
      parser,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    T Function(Object? data)? parser,
  }) {
    return _execute(
      () => _dio.put<Map<String, dynamic>>(path, data: data),
      parser,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    T Function(Object? data)? parser,
  }) {
    return _execute(
      () => _dio.patch<Map<String, dynamic>>(path, data: data),
      parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? data,
    T Function(Object? data)? parser,
  }) {
    return _execute(
      () => _dio.delete<Map<String, dynamic>>(path, data: data),
      parser,
    );
  }

  Future<ApiResponse<T>> _execute<T>(
    Future<Response<Map<String, dynamic>>> Function() request,
    T Function(Object? data)? parser,
  ) async {
    try {
      final response = await request();
      final body = response.data;

      if (body == null) {
        throw const ApiException(
          'The server returned an empty response. Please try again.',
        );
      }

      return ApiResponse<T>.fromJson(body, dataParser: parser);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<bool> _refreshSession() {
    final existing = _refreshFuture;
    if (existing != null) {
      return existing;
    }

    final future = _performRefresh();
    _refreshFuture = future.whenComplete(() => _refreshFuture = null);
    return _refreshFuture!;
  }

  Future<bool> _performRefresh() async {
    try {
      final refreshToken = await _session.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        _refreshPath,
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      final data = body?['data'];

      if (data is! Map) {
        return false;
      }

      final accessToken = data['accessToken'];
      final nextRefreshToken = data['refreshToken'];

      if (accessToken is! String || nextRefreshToken is! String) {
        return false;
      }

      await _session.saveSession(
        accessToken: accessToken,
        refreshToken: nextRefreshToken,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleSessionExpired() async {
    await _session.clearSession();

    if (Get.context == null || Get.currentRoute == AppRoutes.auth) {
      return;
    }

    Get.offAllNamed(AppRoutes.auth);
  }

  DioException _sessionExpiredError(RequestOptions requestOptions) {
    return DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      error: const ApiException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      ),
    );
  }

  static BaseOptions _options() {
    return BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }
}
