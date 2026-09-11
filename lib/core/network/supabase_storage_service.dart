import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'supabase_client.dart';

/// Uploads images to Supabase Storage buckets and returns their public URL.
///
/// Buckets currently used by the app (create them once via the SQL script
/// in `supabase/storage_setup.sql`): `product-images`, `avatars`,
/// `company-logos`.
class SupabaseStorageService {
  SupabaseStorageService._();

  static const _uuid = Uuid();

  /// Uploads [bytes] into [bucket] and returns its public URL.
  ///
  /// - [folder] groups files inside the bucket (e.g. a seller id) — pass
  ///   null to upload flat at the bucket root.
  /// - [fileNameHint] gives the object a stable name (e.g. a user id) so a
  ///   re-upload overwrites the previous file instead of piling up; pass
  ///   null to always create a new file with a random name.
  /// - [extension] should match the picked file (jpg/png/webp, …).
  static Future<String> uploadImage({
    required String bucket,
    required Uint8List bytes,
    String? folder,
    String? fileNameHint,
    String extension = 'jpg',
  }) async {
    final safeExt = extension.replaceAll('.', '').toLowerCase();
    final name = fileNameHint ?? _uuid.v4();
    final path = folder != null && folder.isNotEmpty ? '$folder/$name.$safeExt' : '$name.$safeExt';

    final storage = SupabaseService.client.storage.from(bucket);
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/${safeExt == 'jpg' ? 'jpeg' : safeExt}',
        upsert: true,
      ),
    );
    // Cache-bust so the UI shows the new file immediately instead of a
    // stale cached copy at the same path (relevant when fileNameHint is
    // reused, e.g. re-uploading an avatar).
    return '${storage.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
