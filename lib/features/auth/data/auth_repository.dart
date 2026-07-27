import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cut_above/core/network/api_result.dart';
import 'package:cut_above/core/supabase/supabase_provider.dart';

class AuthRepository {
  Future<ApiResult<User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) {
        return const ApiError<User>(message: 'Login failed');
      }
      return ApiSuccess<User>(res.user!);
    } on AuthException catch (e) {
      return ApiError<User>(message: e.message);
    } catch (e) {
      return ApiError<User>(message: 'Unexpected error: $e');
    }
  }

  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  User? get currentUser => supabaseClient.auth.currentUser;
}
