import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/dark_theme.dart';
import 'theme/light_theme.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/theme_provider.dart';
import 'screens/auth_wrapper.dart';
import 'config/environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  bool envLoaded = false;
  try {
    await dotenv.load(fileName: '.env');
    envLoaded = true;
    print('✅ .env file loaded successfully');
  } catch (e) {
    print('⚠️ Note: .env file not found, using environment-based credentials');
  }

  // Get Supabase credentials
  // Priority: .env overrides > AppConfig (environment-aware staging/production)
  final supabaseUrl = envLoaded ? (dotenv.env['SUPABASE_URL'] ?? AppConfig.supabaseConfig.url) : AppConfig.supabaseConfig.url;
  final supabaseAnonKey = envLoaded ? (dotenv.env['SUPABASE_ANON_KEY'] ?? AppConfig.supabaseConfig.anonKey) : AppConfig.supabaseConfig.anonKey;

  // Verify credentials are available
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception('Supabase credentials not configured. Check .env file or environment config.');
  }

  // Determine which environment we're running in
  final environmentName = AppConfig.environmentName;
  final projectName = AppConfig.supabaseProjectName;

  print('🌍 Environment: $environmentName');
  print('📦 Supabase Project: $projectName');
  print('🔐 Supabase URL: $supabaseUrl');
  print('🔐 Initializing Supabase...');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  print('✅ Supabase initialized successfully for $environmentName');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AuthService(),
              ),
              ChangeNotifierProvider(
                create: (_) => ThemeProvider(snapshot.data!),
              ),
              ChangeNotifierProvider(
                create: (_) => ApiService(snapshot.data!),
              ),
            ],
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return MaterialApp(
                  title: 'WebAudit Pro - Website Audit Tool',
                  theme: themeProvider.isDarkMode
                      ? DarkAppTheme.darkTheme
                      : LightAppTheme.lightTheme,
                  home: const AuthWrapper(),
                );
              },
            ),
          );
        }
        // Show loading screen while initializing SharedPreferences
        // Wrap with MaterialApp to provide Directionality context
        return MaterialApp(
          title: 'WebAudit Pro - Website Audit Tool',
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            backgroundColor: const Color(0xFFF6F8FF),
            body: const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}
