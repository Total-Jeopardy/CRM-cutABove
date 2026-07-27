import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cut_above/core/supabase/supabase_provider.dart';

class PhotoUploadService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndUpload({required String shopId}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return uploadXFile(picked, shopId);
  }

  Future<String?> captureAndUpload({required String shopId}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return uploadXFile(picked, shopId);
  }

  Future<String?> uploadXFile(XFile file, String shopId) async {
    try {
      final bytes = await file.readAsBytes();
      var ext = file.path.split('.').last.toLowerCase();
      if (ext.isEmpty || ext.length > 5) ext = 'jpg';
      final path = 'shops/$shopId/front.$ext';
      await supabaseClient.storage.from('shop-photos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return supabaseClient.storage.from('shop-photos').getPublicUrl(path);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PhotoUploadService: $e');
      }
      return null;
    }
  }
}
