import 'package:dio/dio.dart';

import 'api_result.dart';
import 'token_storage.dart';

const String _refreshPath = '/api/v1/auth/refresh';
const String _retryAfterRefreshExtraKey = '__dio_client_retry_after_refresh';

/// HTTP client with bearer auth, refresh-on-401, and [ApiResult]-based errors.
class DioClient {
  DioClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    required void Function() onLogout,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {'Accept': 'application/json'},
      ),
    );
    _dio.interceptors.add(
      _AuthInterceptor(
        dio: _dio,
        tokenStorage: tokenStorage,
        onLogout: onLogout,
      ),
    );
  }

  late final Dio _dio;

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    });
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    });
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    });
  }

  Future<ApiResult<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    });
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _guard(() async {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    });
  }

  Future<ApiResult<T>> _guard<T>(Future<T> Function() run) async {
    try {
      final data = await run();
      return ApiSuccess(data);
    } on DioException catch (e) {
      return _mapDioException(e);
    }
  }
}

ApiError<T> _mapDioException<T>(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return ApiError(
        message: 'Request timed out. Please try again.',
        statusCode: e.response?.statusCode,
      );
    case DioExceptionType.connectionError:
      return const ApiError(
        message: 'No internet connection.',
        statusCode: null,
      );
    case DioExceptionType.badResponse:
      return ApiError(
        message: _messageFromResponse(e.response),
        statusCode: e.response?.statusCode,
      );
    case DioExceptionType.cancel:
      return const ApiError(message: 'Request was cancelled.', statusCode: null);
    case DioExceptionType.badCertificate:
      return const ApiError(
        message: 'Could not verify the server certificate.',
        statusCode: null,
      );
    case DioExceptionType.unknown:
      return ApiError(
        message: e.message?.isNotEmpty == true
            ? e.message!
            : 'An unexpected error occurred.',
        statusCode: e.response?.statusCode,
      );
  }
}

String _messageFromResponse(Response<dynamic>? response) {
  final data = response?.data;
  if (data is Map) {
    final message =
        data['message'] ?? data['error'] ?? data['detail'] ?? data['title'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) {
      final first = message.first;
      if (first is String) return first;
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return 'Request failed';
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required void Function() onLogout,
  })  : _dio = dio,
        _tokenStorage = tokenStorage,
        _onLogout = onLogout;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function() _onLogout;
  Future<void>? _refreshFuture;

  bool _isRefreshRequest(RequestOptions options) =>
      options.path.contains(_refreshPath);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isRefreshRequest(options)) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        options.headers.remove('Authorization');
      }
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final request = err.requestOptions;

    if (_isRefreshRequest(request)) {
      await _tokenStorage.clearTokens();
      _onLogout();
      handler.next(err);
      return;
    }

    if (request.extra[_retryAfterRefreshExtraKey] == true) {
      await _tokenStorage.clearTokens();
      _onLogout();
      handler.next(err);
      return;
    }

    try {
      await _refreshWithCoalescing();
      final access = await _tokenStorage.getAccessToken();
      if (access == null || access.isEmpty) {
        await _tokenStorage.clearTokens();
        _onLogout();
        handler.next(err);
        return;
      }
      request.headers['Authorization'] = 'Bearer $access';
      request.extra[_retryAfterRefreshExtraKey] = true;
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clearTokens();
        _onLogout();
      }
      handler.next(err);
    } catch (_) {
      handler.next(err);
    }
  }

  Future<void> _refreshWithCoalescing() {
    _refreshFuture ??= _performRefresh().whenComplete(() {
      _refreshFuture = null;
    });
    return _refreshFuture!;
  }

  Future<void> _performRefresh() async {
    final refresh = await _tokenStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      await _tokenStorage.clearTokens();
      _onLogout();
      throw DioException(
        requestOptions: RequestOptions(path: _refreshPath),
        type: DioExceptionType.unknown,
        message: 'Missing refresh token',
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      _refreshPath,
      data: {'refresh_token': refresh},
      options: Options(
        contentType: Headers.jsonContentType,
        headers: {'Accept': 'application/json'},
      ),
    );

    final raw = response.data;
    if (raw is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    final body = Map<String, dynamic>.from(raw as Map<dynamic, dynamic>);

    final access = _readString(body, const ['access_token', 'accessToken']);
    if (access == null || access.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'Invalid refresh response',
      );
    }

    final nextRefresh =
        _readString(body, const ['refresh_token', 'refreshToken']) ?? refresh;

    await _tokenStorage.saveTokens(access, nextRefresh);
  }
}

String? _readString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final v = map[key];
    if (v is String && v.isNotEmpty) return v;
  }
  return null;
}
