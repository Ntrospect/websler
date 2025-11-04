import 'package:flutter/foundation.dart';

/// Environment enum for staging vs production
enum Environment { staging, production }

/// Supabase configuration for each environment
class SupabaseConfig {
  final String url;
  final String anonKey;

  const SupabaseConfig({
    required this.url,
    required this.anonKey,
  });
}

/// App configuration that automatically detects environment
class AppConfig {
  /// Determines environment based on:
  /// 1. Build-time --dart-define=ENVIRONMENT (takes precedence)
  /// 2. Debug builds (flutter run) use staging
  /// 3. Release builds (flutter build web) use production by default
  static Environment get environment {
    // First check if ENVIRONMENT was passed via --dart-define
    const String envFromDefine = String.fromEnvironment('ENVIRONMENT', defaultValue: '');

    if (envFromDefine.isNotEmpty) {
      if (envFromDefine == 'staging') {
        return Environment.staging;
      } else if (envFromDefine == 'production') {
        return Environment.production;
      }
    }

    // Fall back to build mode detection
    if (kDebugMode) {
      return Environment.staging;
    } else {
      return Environment.production;
    }
  }

  /// Get the appropriate Supabase configuration for current environment
  static SupabaseConfig get supabaseConfig {
    switch (environment) {
      case Environment.staging:
        return const SupabaseConfig(
          // Staging Supabase (for testing)
          url: 'https://kmlhslmkdnjakkpluwup.supabase.co',
          anonKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImttbGhzbG1rZG5qYWtrcGx1d3VwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MTQ5NzMsImV4cCI6MjA3NzI5MDk3M30.LA9ZqH3KShFU7da_25LjSJisHRkqd-8lkNlgOheNUW4',
        );

      case Environment.production:
        return const SupabaseConfig(
          // Production Supabase (live)
          url: 'https://vwnbhsmfpxdfcvqnzddc.supabase.co',
          anonKey:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3bmJoc21mcHhkZmN2cW56ZGRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIxNTg5MjMsImV4cCI6MjA3NzUxODkyM30.KNCWrSvMo6cOiABqERieO00D1bWNiNf6mI4-XdXS1bc',
        );
    }
  }

  /// Get environment name for display
  static String get environmentName {
    return environment == Environment.staging ? 'Staging' : 'Production';
  }

  /// Get Supabase project name for display
  static String get supabaseProjectName {
    return environment == Environment.staging
        ? 'websler-pro-staging'
        : 'websler-pro';
  }
}
