import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/theme_provider.dart';
import '../models/auth_state.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'ai_audit_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showSplash = true;
  bool _showSignup = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = context.read<AuthService>();
    final apiService = context.read<ApiService>();

    // Wire services together
    authService.setApiService(apiService);

    // Initialize auth and restore session
    await authService.initialize();

    // Hide splash after 2 seconds to show the splash screen animation
    // The SplashScreen widget has internal animations that run for 1.5s,
    // plus a 2-second delay before the onSplashComplete callback would fire
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _showSplash = false);
    }
  }

  void _switchToSignup() {
    setState(() => _showSignup = true);
  }

  void _switchToLogin() {
    setState(() => _showSignup = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Show splash while initializing
        if (_showSplash) {
          return const SplashScreen(
            onSplashComplete: null, // Splash will auto-hide after 2 seconds
          );
        }

        // If authenticated, show main app
        if (authService.isAuthenticated) {
          return const MainApp();
        }

        // If authenticating, show "Check your email" screen
        if (authService.authState.status == AuthStatus.authenticating) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Email icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.mail_outline,
                          size: 40,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Main message
                      const Text(
                        'Check Your Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email address
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          authService.authState.email ?? 'your-email@example.com',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Instructions
                      const Text(
                        'We\'ve sent you a confirmation link. Click the link in the email to verify your account and complete the signup process.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Loading indicator
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),

                      // Status message
                      const Text(
                        'Waiting for email confirmation...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Hint
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          border: Border.all(color: Colors.amber.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '💡 Tip',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check your spam/junk folder if you don\'t see the email in your inbox.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Show signup or login screen
        if (_showSignup) {
          return SignupScreen(
            onSwitchToLogin: _switchToLogin,
          );
        } else {
          return LoginScreen(
            onSwitchToSignup: _switchToSignup,
          );
        }
      },
    );
  }
}

/// Main app widget (Home, History, Settings)
class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;
  bool _isScrolled = false;

  /// Clean navigation structure:
  /// - Home: Websler summary generator
  /// - AI Audit: AI Discoverability Audit
  /// - History: Unified history (summaries + audits with upgrade option)
  /// - Settings: Theme & preferences
  final List<Widget> _screens = [
    const HomeScreen(),
    const AIAuditScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isScrolled = false;
    });
  }

  void _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final isScrolled = notification.metrics.pixels > 10;
      if (isScrolled != _isScrolled) {
        setState(() {
          _isScrolled = isScrolled;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final bgColor = themeProvider.isDarkMode
            ? const Color(0xFF0F1419)
            : Colors.white;
        final scrolledBgColor = themeProvider.isDarkMode
            ? const Color(0xFF0F1419).withOpacity(0.95)
            : Colors.white.withOpacity(0.8);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: 68,
            elevation: 0,
            backgroundColor: _isScrolled ? scrolledBgColor : bgColor,
            surfaceTintColor: bgColor,
            title: Consumer<AuthService>(
              builder: (context, authService, _) {
                final webslerLogo = themeProvider.isDarkMode
                    ? 'assets/websler_pro-dark-theme.png'
                    : 'assets/websler_pro.png';
                return SizedBox(
                  width: 165,
                  height: 69,
                  child: Image.asset(
                    webslerLogo,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 32),
                child: SizedBox(
                  width: 151,
                  height: 54,
                  child: Image.asset(
                    themeProvider.isDarkMode
                        ? 'assets/jumoki_white_transparent_bg.png'
                        : 'assets/jumoki_coloured_transparent_bg.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _onScroll(notification);
              return false;
            },
            child: _screens[_selectedIndex],
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology),
                label: 'AI Audit',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}
