import 'package:cut_above/core/network/api_result.dart';
import 'package:cut_above/core/network/dio_client.dart';

import 'auth_tokens.dart';

class AuthRepository {
  AuthRepository(this._client);

  final DioClient _client;

  static const String _loginPath = '/api/v1/auth/login';

  Future<ApiResult<AuthTokens>> login(String phone, String password) async {
    final result = await _client.post<Map<String, dynamic>>(
      _loginPath,
      data: {'phone': phone, 'password': password},
    );

    return switch (result) {
      ApiSuccess(:final data) => _mapLoginBody(data),
      ApiError(:final message, :final statusCode) => ApiError<AuthTokens>(
          message: message,
          statusCode: statusCode,
        ),
    };
  }

  ApiResult<AuthTokens> _mapLoginBody(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const ApiError<AuthTokens>(
        message: 'Empty response from server',
        statusCode: null,
      );
    }
    final root = data['data'];
    final Map<String, dynamic> map;
    if (root is Map) {
      map = Map<String, dynamic>.from(root);
    } else {
      map = data;
    }
    try {
      return ApiSuccess(AuthTokens.fromJson(map));
    } on FormatException catch (_) {
      return const ApiError<AuthTokens>(
        message: 'Could not read login response',
        statusCode: null,
      );
    }
  }
}
