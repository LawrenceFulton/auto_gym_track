import 'package:flutter/foundation.dart';

import '../../data/services/openrouter_client.dart';
import '../../data/services/openrouter_key_store.dart';

class ApiKeyController extends ChangeNotifier {
  ApiKeyController({required OpenRouterKeyStore keyStore}) : _keyStore = keyStore;

  final OpenRouterKeyStore _keyStore;

  OpenRouterClient? _client;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  OpenRouterClient? get client => _client;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await _keyStore.loadKey();
      const env = String.fromEnvironment('OPENROUTER_API_KEY');
      final resolved = saved ?? (env.isEmpty ? null : env);

      if (resolved != null) {
        if (saved == null && env.isNotEmpty) {
          await _keyStore.saveKey(env);
        }
        _client = OpenRouterClient(apiKey: resolved);
      }
    } catch (exception) {
      _error = 'Failed to read saved key: $exception';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveKey(String key) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _keyStore.saveKey(key);
      _client = OpenRouterClient(apiKey: key);
    } catch (exception) {
      _error = 'Failed to save key: $exception';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
