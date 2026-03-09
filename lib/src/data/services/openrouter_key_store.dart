import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class OpenRouterKeyStore {
  Future<String?> loadKey();
  Future<void> saveKey(String key);
  Future<void> clearKey();
}

class SecureOpenRouterKeyStore implements OpenRouterKeyStore {
  const SecureOpenRouterKeyStore({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _apiKeyStorageKey = 'openrouter_api_key';
  static String? _sessionFallbackKey;
  final FlutterSecureStorage _storage;

  @override
  Future<String?> loadKey() async {
    try {
      final key = await _storage.read(key: _apiKeyStorageKey);
      if (key == null || key.trim().isEmpty) {
        return _sessionFallbackKey;
      }
      return key.trim();
    } on MissingPluginException {
      return _sessionFallbackKey;
    }
  }

  @override
  Future<void> saveKey(String key) async {
    final trimmed = key.trim();
    try {
      await _storage.write(key: _apiKeyStorageKey, value: trimmed);
    } on MissingPluginException {
      // Keep app functional even if secure-storage plugin registration failed.
      _sessionFallbackKey = trimmed;
    }
  }

  @override
  Future<void> clearKey() async {
    try {
      await _storage.delete(key: _apiKeyStorageKey);
    } on MissingPluginException {
      _sessionFallbackKey = null;
    }
  }
}

class InMemoryOpenRouterKeyStore implements OpenRouterKeyStore {
  InMemoryOpenRouterKeyStore({String? seedKey}) : _key = seedKey;

  String? _key;

  @override
  Future<void> clearKey() async {
    _key = null;
  }

  @override
  Future<String?> loadKey() async {
    if (_key == null || _key!.trim().isEmpty) {
      return null;
    }
    return _key!.trim();
  }

  @override
  Future<void> saveKey(String key) async {
    _key = key.trim();
  }
}
