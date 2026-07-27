import 'package:cut_above/core/supabase/supabase_provider.dart';
import 'package:cut_above/features/shops/data/profile_model.dart';

class ProfileRepository {
  Future<List<ProfileModel>> fetchTeam() async {
    final data = await supabaseClient
        .from('profiles')
        .select()
        .order('full_name');
    final list = data as List<dynamic>;
    return list
        .map(
          (j) => ProfileModel.fromJson(Map<String, dynamic>.from(j as Map)),
        )
        .toList();
  }

  Future<ProfileModel?> fetchCurrentUser() async {
    final uid = supabaseClient.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await supabaseClient
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> upsertProfile({
    required String fullName,
    required String role,
  }) async {
    final uid = supabaseClient.auth.currentUser!.id;
    await supabaseClient.from('profiles').upsert({
      'id': uid,
      'full_name': fullName,
      'role': role,
    });
  }
}
