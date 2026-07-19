import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Error dari backend, membawa kode mesin + pesan yang bisa
/// ditampilkan ke user.
class ApiException implements Exception {
  ApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}

class AuthResult {
  const AuthResult({
    required this.token,
    required this.email,
    required this.displayName,
    required this.isVerified,
  });

  final String token;
  final String email;
  final String displayName;
  final bool isVerified;
}

/// Payload GET/POST /sync — baris mentah JSON (snake_case) per entitas.
/// Konversi ke/dari baris drift dilakukan SyncService.
class SyncPayload {
  SyncPayload({
    this.serverTime,
    this.profiles = const [],
    this.boards = const [],
    this.cells = const [],
    this.symbols = const [],
  });

  final DateTime? serverTime;
  final List<Map<String, dynamic>> profiles;
  final List<Map<String, dynamic>> boards;
  final List<Map<String, dynamic>> cells;
  final List<Map<String, dynamic>> symbols;

  bool get isEmpty =>
      profiles.isEmpty && boards.isEmpty && cells.isEmpty && symbols.isEmpty;

  int get length =>
      profiles.length + boards.length + cells.length + symbols.length;

  Map<String, dynamic> toJson() => {
        'profiles': profiles,
        'boards': boards,
        'cells': cells,
        'symbols': symbols,
      };

  static List<Map<String, dynamic>> _rows(dynamic v) =>
      (v as List? ?? const []).cast<Map<String, dynamic>>();

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
        serverTime: DateTime.parse(json['server_time'] as String),
        profiles: _rows(json['profiles']),
        boards: _rows(json['boards']),
        cells: _rows(json['cells']),
        symbols: _rows(json['symbols']),
      );
}

class ShareCode {
  const ShareCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// Klien REST API backend (`/api/v1`).
class ApiClient {
  ApiClient({required this.baseUrl, this.token, http.Client? client})
      : _client = client ?? http.Client();

  /// Tanpa trailing slash, mis. `https://aac.up.railway.app`.
  String baseUrl;
  String? token;

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl/api/v1$path').replace(queryParameters: query);

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  dynamic _decode(http.Response res, String what) {
    final body = res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    if (body is Map<String, dynamic> && body['error'] is Map<String, dynamic>) {
      final e = body['error'] as Map<String, dynamic>;
      throw ApiException(res.statusCode, '${e['code']}', '${e['message']}');
    }
    throw ApiException(res.statusCode, 'http_error', '$what gagal (${res.statusCode})');
  }

  AuthResult _authResult(dynamic body) {
    final map = body as Map<String, dynamic>;
    final user = map['user'] as Map<String, dynamic>;
    return AuthResult(
      token: map['token'] as String,
      email: user['email'] as String,
      displayName: user['display_name'] as String? ?? '',
      isVerified: user['is_verified'] as bool? ?? false,
    );
  }

  Future<AuthResult> register(
      String email, String password, String displayName) async {
    final res = await _client.post(_uri('/auth/register'),
        headers: _headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'display_name': displayName,
        }));
    return _authResult(_decode(res, 'Registrasi'));
  }

  Future<AuthResult> login(String email, String password) async {
    final res = await _client.post(_uri('/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}));
    return _authResult(_decode(res, 'Login'));
  }

  Future<AuthResult> loginWithGoogle(String idToken) async {
    final res = await _client.post(_uri('/auth/google'),
        headers: _headers(), body: jsonEncode({'id_token': idToken}));
    return _authResult(_decode(res, 'Login Google'));
  }

  /// Minta email verifikasi dikirim ulang (butuh sudah login).
  Future<void> resendVerification() async {
    final res = await _client
        .post(_uri('/auth/resend-verification'), headers: _headers());
    _decode(res, 'Kirim ulang verifikasi');
  }

  /// Status verifikasi bisa berubah di luar app (user klik link di
  /// email) — dipanggil ulang biar UI ikut ter-update.
  Future<bool> fetchIsVerified() async {
    final res = await _client.get(_uri('/me'), headers: _headers(json: false));
    final body = _decode(res, 'Ambil profil') as Map<String, dynamic>;
    return body['is_verified'] as bool? ?? false;
  }

  Future<SyncPayload> syncPull({DateTime? since}) async {
    final res = await _client.get(
      _uri('/sync', {
        if (since != null) 'since': since.toUtc().toIso8601String(),
      }),
      headers: _headers(json: false),
    );
    return SyncPayload.fromJson(
        _decode(res, 'Sinkronisasi (pull)') as Map<String, dynamic>);
  }

  /// Mengembalikan server_time untuk disimpan sebagai `since` berikutnya.
  Future<DateTime> syncPush(SyncPayload payload) async {
    final res = await _client.post(_uri('/sync'),
        headers: _headers(), body: jsonEncode(payload.toJson()));
    final body = _decode(res, 'Sinkronisasi (push)') as Map<String, dynamic>;
    return DateTime.parse(body['server_time'] as String);
  }

  /// Upload gambar; mengembalikan URL ABSOLUT (baseUrl + /uploads/x).
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('POST', _uri('/uploads'))
      ..headers.addAll(_headers(json: false))
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename));
    final res = await http.Response.fromStream(await _client.send(req));
    final body = _decode(res, 'Upload gambar') as Map<String, dynamic>;
    return '$baseUrl${body['url']}';
  }

  Future<ShareCode> shareBoard(String boardId) async {
    final res = await _client.post(_uri('/boards/$boardId/share'),
        headers: _headers());
    final body = _decode(res, 'Bagikan papan') as Map<String, dynamic>;
    return ShareCode(
      code: body['code'] as String,
      expiresAt: DateTime.parse(body['expires_at'] as String),
    );
  }

  Future<void> importBoard(String code, String profileId) async {
    final res = await _client.post(_uri('/boards/import'),
        headers: _headers(),
        body: jsonEncode({'code': code, 'profile_id': profileId}));
    _decode(res, 'Impor papan');
  }
}
