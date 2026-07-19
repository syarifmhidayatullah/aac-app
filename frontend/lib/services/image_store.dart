import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Penyimpanan gambar custom pengguna (foto kamera/galeri).
///
/// - Mobile/desktop: file disimpan di `<documents>/images/<uuid>.<ext>`;
///   DB menyimpan path RELATIF (`images/<uuid>.jpg`) karena path absolut
///   container berubah antar install/update di iOS.
/// - Web: tidak ada filesystem — gambar disimpan langsung sebagai
///   data URI base64 di kolom `imageUrl`.
class ImageStore {
  ImageStore._(this._baseDir);

  /// Direktori dokumen app; null di web.
  final Directory? _baseDir;

  static Future<ImageStore> init() async {
    if (kIsWeb) return ImageStore._(null);
    final docs = await getApplicationDocumentsDirectory();
    await Directory('${docs.path}/images').create(recursive: true);
    return ImageStore._(docs);
  }

  /// Untuk test: pakai direktori sembarang.
  @visibleForTesting
  ImageStore.forTesting(Directory baseDir) : _baseDir = baseDir;

  /// Simpan gambar terpilih; mengembalikan string untuk kolom
  /// `symbols.imageUrl` (path relatif, atau data URI di web).
  Future<String> saveImage(XFile picked) async {
    final bytes = await picked.readAsBytes();
    if (kIsWeb) {
      final mime = picked.mimeType ?? 'image/jpeg';
      return 'data:$mime;base64,${base64Encode(bytes)}';
    }
    final ext = _extension(picked);
    final relative = 'images/${_uuid.v4()}$ext';
    final file = File('${_baseDir!.path}/$relative');
    await file.writeAsBytes(bytes);
    return relative;
  }

  /// Resolve path relatif dari DB menjadi [File]. Jangan dipanggil di web.
  File resolve(String relativePath) =>
      File('${_baseDir!.path}/$relativePath');

  String _extension(XFile picked) {
    final name = picked.name.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final ext = name.substring(dot);
    const allowed = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'};
    return allowed.contains(ext) ? ext : '.jpg';
  }
}
