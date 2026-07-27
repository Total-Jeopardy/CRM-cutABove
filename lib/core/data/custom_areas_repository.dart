import 'package:cut_above/core/supabase/supabase_provider.dart';

class CustomAreasRepository {
  Future<List<String>> fetchAll() async {
    final data = await supabaseClient
        .from('custom_areas')
        .select('name')
        .order('name');
    return (data as List).map((j) => j['name'] as String).toList();
  }

  Future<void> add(String name) async {
    try {
      await supabaseClient.from('custom_areas').insert({
        'name': name,
        'added_by': supabaseClient.auth.currentUser!.id,
      });
    } catch (_) {
      // Ignore duplicate — unique constraint handles it
    }
  }
}
