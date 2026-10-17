import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/entry_models.dart';

SupabaseClient get _client => Supabase.instance.client;

/// Uploads from disk so a video is not copied into memory first.
Future<PickedUpload> uploadLocalFile(
  String filePath,
  String type, {
  String? contentType,
}) async {
  final userId = _client.auth.currentUser!.id;
  final dot = filePath.lastIndexOf('.');
  final rawExt = dot == -1 ? '' : filePath.substring(dot + 1).toLowerCase();
  final ext = rawExt.isEmpty || rawExt.length > 4
      ? (type == 'video' ? 'mp4' : 'jpg')
      : rawExt;
  final path =
      '$userId/${DateTime.now().microsecondsSinceEpoch}-$type.$ext';
  await _client.storage.from('photos').upload(
        path,
        File(filePath),
        fileOptions: FileOptions(
          contentType: contentType ??
              (type == 'video' ? 'video/mp4' : 'image/jpeg'),
        ),
      );
  return PickedUpload(
    path: path,
    url: _client.storage.from('photos').getPublicUrl(path),
  );
}

Future<PickedUpload> uploadPickedFile(XFile file, String type) {
  return uploadLocalFile(file.path, type, contentType: file.mimeType);
}

Future<PickedUpload> uploadVideoFile(XFile file) {
  return uploadLocalFile(
    file.path,
    'video',
    contentType: file.mimeType ?? 'video/mp4',
  );
}
