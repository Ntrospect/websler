import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/environment.dart';

/// Environment configuration loader
/// Provides centralized access to environment variables
class EnvConfig {
  static String? _cachedApiUrl;

  /// Safely get a value from dotenv environment, handling NotInitializedError
  static String? _safeGet(String key) {
    try {
      return dotenv.env[key];
    } catch (e) {
      print('⚠️ EnvConfig: .env not initialized, returning null for $key');
      return null;
    }
  }

  /// Get API base URL from environment or return default
  /// Tries .env first, then uses environment-aware default
  static String getApiUrl() {
    if (_cachedApiUrl != null) return _cachedApiUrl!;

    // Try to load from .env (works locally)
    final envApiUrl = _safeGet('API_BASE_URL');
    if (envApiUrl != null) {
      _cachedApiUrl = envApiUrl;
      return _cachedApiUrl!;
    }

    // Fall back to environment-aware default
    // Both staging and production use the HTTPS api.websler.pro domain
    _cachedApiUrl = 'https://api.websler.pro';
    return _cachedApiUrl!;
  }

  /// Get Supabase URL from environment
  static String? getSupabaseUrl() {
    return _safeGet('SUPABASE_URL');
  }

  /// Get Supabase anon key from environment
  static String? getSupabaseAnonKey() {
    return _safeGet('SUPABASE_ANON_KEY');
  }

  /// Get environment (development, staging, production)
  static String getEnvironment() {
    return _safeGet('ENVIRONMENT') ?? 'development';
  }

  /// Check if in production environment
  static bool isProduction() {
    return getEnvironment() == 'production';
  }
}
