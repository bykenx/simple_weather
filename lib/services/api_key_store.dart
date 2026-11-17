import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Credentials use platform secure storage; legacy preferences are removed
/// only after a successful, verified migration.
class ApiKeyStore {
  static const _key = 'api_key';
  final FlutterSecureStorage storage;
  Future<String?>? _pendingRead;
  Future<void> _writes = Future.value();

  ApiKeyStore({this.storage = const FlutterSecureStorage()});

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<String?> read() {
    if (_pendingRead != null) return _pendingRead!;
    late final Future<String?> pending;
    pending = _serial(_readAndMigrate).whenComplete(() {
      if (identical(_pendingRead, pending)) _pendingRead = null;
    });
    _pendingRead = pending;
    return pending;
  }

  Future<String?> _readAndMigrate() async {
    final secure = await storage.read(key: _key);
    final prefs = await SharedPreferences.getInstance();
    if (secure != null) {
      await prefs.remove(_key);
      return secure;
    }
    final legacy = prefs.getString(_key);
    if (legacy == null || legacy.isEmpty) return null;
    await _writeVerified(legacy);
    await prefs.remove(_key);
    return legacy;
  }

  Future<void> _writeVerified(String value) async {
    await storage.write(key: _key, value: value);
    if (await storage.read(key: _key) != value) {
      throw StateError('API密钥保存失败，请重试');
    }
  }

  Future<void> write(String value) {
    // New reads must wait for this save, rather than reuse an older read.
    _pendingRead = null;
    return _serial(() async {
      await _writeVerified(value.trim());
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    });
  }
}
