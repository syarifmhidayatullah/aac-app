import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db.dart';
import '../services/api_client.dart';
import '../services/image_store.dart';
import '../services/sync_service.dart';

/// State akun & sinkronisasi: sesi login (token di shared_preferences),
/// waktu sync terakhir, dan operasi login/registrasi/sync/berbagi.
///
/// App tetap berfungsi penuh tanpa login (offline-first); akun hanya
/// untuk sync antar perangkat dan berbagi papan.
class AccountState extends ChangeNotifier {
  AccountState({
    required AppDatabase db,
    required SharedPreferences prefs,
    ImageStore? imageStore,
    ApiClient? api, // untuk test
  })  : _db = db,
        _prefs = prefs,
        _imageStore = imageStore,
        _api = api;

  static const defaultBaseUrl = String.fromEnvironment(
    'AAC_API_URL',
    defaultValue: 'http://localhost:8080',
  );

  final AppDatabase _db;
  final SharedPreferences _prefs;
  final ImageStore? _imageStore;

  ApiClient? _api;
  SyncService? _syncService;

  String _baseUrl = defaultBaseUrl;
  String? _token;
  String? _email;
  String? _displayName;
  DateTime? _lastSync;
  String? _activeProfileId;
  bool _busy = false;
  String? _lastError;

  String get baseUrl => _baseUrl;
  bool get loggedIn => _token != null;
  String? get email => _email;
  String? get displayName => _displayName;
  DateTime? get lastSync => _lastSync;
  String? get activeProfileId => _activeProfileId;
  bool get busy => _busy;
  String? get lastError => _lastError;

  void init() {
    _baseUrl = _prefs.getString('baseUrl') ?? defaultBaseUrl;
    _token = _prefs.getString('token');
    _email = _prefs.getString('email');
    _displayName = _prefs.getString('displayName');
    _activeProfileId = _prefs.getString('activeProfileId');
    final ts = _prefs.getString('lastSync');
    _lastSync = ts == null ? null : DateTime.tryParse(ts);
    if (_token != null) {
      _client()
        ..baseUrl = _baseUrl
        ..token = _token;
    }
  }

  ApiClient _client() => _api ??= ApiClient(baseUrl: _baseUrl, token: _token);

  SyncService _sync() => _syncService ??=
      SyncService(db: _db, api: _client(), imageStore: _imageStore);

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceFirst(RegExp(r'/+$'), '');
    _client().baseUrl = _baseUrl;
    await _prefs.setString('baseUrl', _baseUrl);
    notifyListeners();
  }

  Future<void> setActiveProfile(String profileId) async {
    _activeProfileId = profileId;
    await _prefs.setString('activeProfileId', profileId);
  }

  /// Login atau registrasi, lalu sinkronisasi pertama.
  ///
  /// Mengembalikan id profile aktif BARU kalau data lokal diganti data
  /// server (login di perangkat baru) — pemanggil harus memuat ulang
  /// state komunikasi; null kalau data lokal dipertahankan.
  Future<String?> signIn({
    required String email,
    required String password,
    bool register = false,
    String displayName = '',
  }) async {
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      final api = _client();
      final auth = register
          ? await api.register(email, password, displayName)
          : await api.login(email, password);
      _token = auth.token;
      _email = auth.email;
      _displayName = auth.displayName;
      api.token = auth.token;
      await _prefs.setString('token', auth.token);
      await _prefs.setString('email', auth.email);
      await _prefs.setString('displayName', auth.displayName);

      final result = await _sync().firstSync();
      await _saveLastSync(result.serverTime);
      final newProfile = result.newActiveProfileId;
      if (newProfile != null) await setActiveProfile(newProfile);
      return newProfile;
    } catch (e) {
      _lastError = friendlyError(e);
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Logout hanya menghapus sesi — data lokal tetap ada (offline-first).
  Future<void> logout() async {
    _token = null;
    _email = null;
    _displayName = null;
    _lastSync = null;
    _client().token = null;
    await _prefs.remove('token');
    await _prefs.remove('email');
    await _prefs.remove('displayName');
    await _prefs.remove('lastSync');
    notifyListeners();
  }

  /// Sinkronisasi manual/rutin. Mengembalikan true kalau sukses.
  Future<bool> syncNow() async {
    if (!loggedIn || _busy) return false;
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      final serverTime = await _sync().sync(since: _lastSync);
      await _saveLastSync(serverTime);
      return true;
    } catch (e) {
      _lastError = friendlyError(e);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Bagikan papan: pastikan tersinkron dulu (papan harus ada di
  /// server), lalu minta kode.
  Future<ShareCode> shareBoard(String boardId) async {
    final serverTime = await _sync().sync(since: _lastSync);
    await _saveLastSync(serverTime);
    return _client().shareBoard(boardId);
  }

  /// Impor papan dari kode ke profile aktif, lalu pull hasilnya.
  Future<void> importBoard(String code) async {
    final profileId = _activeProfileId;
    if (profileId == null) throw StateError('no active profile');
    await _client().importBoard(code, profileId);
    final serverTime = await _sync().sync(since: _lastSync);
    await _saveLastSync(serverTime);
  }

  Future<void> _saveLastSync(DateTime t) async {
    _lastSync = t;
    await _prefs.setString('lastSync', t.toUtc().toIso8601String());
  }

  static String friendlyError(Object e) {
    if (e is ApiException) {
      switch (e.code) {
        case 'invalid_credentials':
          return 'Email atau password salah.';
        case 'email_taken':
          return 'Email sudah terdaftar — coba login.';
        case 'not_found':
          return 'Tidak ditemukan — kode salah atau kedaluwarsa.';
        case 'invalid_input':
          return e.message;
      }
      return e.message;
    }
    return 'Tidak bisa terhubung ke server. Periksa koneksi/alamat server.';
  }
}
