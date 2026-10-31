import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DebugLogInterceptor extends Interceptor {
  static const String _startedAtKey = 'debug_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now().microsecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode, failure: err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions options, int? statusCode, {String? failure}) {
    final startedAt = options.extra[_startedAtKey];
    final elapsedMs = startedAt is int
        ? (DateTime.now().microsecondsSinceEpoch - startedAt) ~/ 1000
        : null;
    final status = statusCode?.toString() ?? failure ?? 'failed';
    final duration = elapsedMs == null ? '' : ' (${elapsedMs}ms)';

    debugPrint(
      '[API] ${options.method} ${options.uri.path} -> $status$duration',
    );
  }
}
