import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/dark_theme.dart';
import '../services/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiUrlController;
  late TextEditingController _logoUrlController;
  late TextEditingController _companyNameController;
  late TextEditingController _companyDetailsController;
  late TextEditingController _fullNameController;
  late TextEditingController _passwordController;
  int _auditCount = 0;
  int _summaryCount = 0;
  bool _isLoadingStats = true;
  bool _isSavingBranding = false;
  bool _isPreviewingBranding = false;

  @override
  void initState() {
    super.initState();
    final apiService = context.read<ApiService>();
    _apiUrlController = TextEditingController(text: apiService.apiUrl);
    _logoUrlController = TextEditingController();
    _companyNameController = TextEditingController();
    _companyDetailsController = TextEditingController();
    _fullNameController = TextEditingController();
    _passwordController = TextEditingController();
    _loadPdfBrandingSettings();
    _loadUsageStatistics();
  }

  Future<void> _loadPdfBrandingSettings() async {
    try {
      final authService = context.read<AuthService>();
      final user = authService.currentUser;

      if (user != null) {
        setState(() {
          _logoUrlController.text = user.avatarUrl ?? '';
          _companyNameController.text = user.companyName ?? '';
          _companyDetailsController.text = user.companyDetails ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading branding settings: $e');
    }
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _logoUrlController.dispose();
    _companyNameController.dispose();
    _companyDetailsController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final apiUrl = _apiUrlController.text.trim();

    if (apiUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API URL')),
      );
      return;
    }

    context.read<ApiService>().setApiUrl(apiUrl);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }

  Future<void> _savePdfBrandingSettings() async {
    setState(() => _isSavingBranding = true);

    try {
      final authService = context.read<AuthService>();
      final logoUrl = _logoUrlController.text.trim();
      final companyName = _companyNameController.text.trim();
      final companyDetails = _companyDetailsController.text.trim();

      // Update user profile in Supabase
      await authService.updateUserProfile(
        avatarUrl: logoUrl.isEmpty ? null : logoUrl,
        companyName: companyName.isEmpty ? null : companyName,
        companyDetails: companyDetails.isEmpty ? null : companyDetails,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF branding saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving branding: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error saving PDF branding: $e');
    } finally {
      setState(() => _isSavingBranding = false);
    }
  }

  Future<void> _previewBrandingPdf() async {
    setState(() => _isPreviewingBranding = true);

    try {
      final authService = context.read<AuthService>();
      final apiService = context.read<ApiService>();
      final user = authService.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate a preview PDF with their branding and sample data
      // This creates a test summary PDF so they can see their branding
      const testSummaryId = 'preview-test';
      final filePath = await apiService.generatePdf(
        testSummaryId,
        logoUrl: user.avatarUrl,
        companyName: user.companyName,
        companyDetails: user.companyDetails,
      );

      if (mounted) {
        // Show success dialog with preview info
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('PDF Preview Generated'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your PDF preview has been generated! Here\'s what your clients will see:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (user.avatarUrl != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Logo: Displayed in header',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        if (user.companyName != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Company Name:',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                                Text(
                                  user.companyName!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9018ad),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (user.companyDetails != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Details:',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                user.companyDetails!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Text(
                      'Preview saved to Downloads! You can open it to see the exact layout and styling with your branding.',
                      style: TextStyle(fontSize: 13, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating preview: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error previewing PDF branding: $e');
    } finally {
      setState(() => _isPreviewingBranding = false);
    }
  }

  void _testConnection() async {
    try {
      final apiService = context.read<ApiService>();
      // Try to get history to test connection
      await apiService.getHistory(limit: 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUsageStatistics() async {
    try {
      final apiService = context.read<ApiService>();
      final history = await apiService.getUnifiedHistory(limit: 1000);

      if (mounted) {
        setState(() {
          _auditCount = history.where((a) => a.isAudit).length;
          _summaryCount = history.where((a) => a.isSummary).length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                hintText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = _passwordController.text.trim();
              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 6 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final authService = context.read<AuthService>();
                await authService.updatePassword(password);

                if (mounted) {
                  _passwordController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = context.read<AuthService>();
                await authService.signOut();
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final authService = context.read<AuthService>();
                await authService.deleteAccount();
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 88, 20.0, 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Section
            Consumer<AuthService>(
              builder: (context, authService, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blue.shade100,
                              child: Text(
                                authService.currentUser?.email?[0].toUpperCase() ?? '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              authService.currentUser?.email ?? 'Not available',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _changePassword,
                                    icon: const Icon(Icons.lock),
                                    label: const Text('Change Password'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),

            // Usage Statistics Section
            Text(
              'Usage Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoadingStats
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Audits',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    _auditCount.toString(),
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Summaries',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                  Text(
                                    _summaryCount.toString(),
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // API Settings Section
            Text(
              'API Configuration',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backend API URL',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiUrlController,
                      decoration: InputDecoration(
                        hintText: 'http://140.99.254.83:8000',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The URL where your weblser backend API is hosted.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Test Connection'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveSettings,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Appearance Section
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toggle between light and dark theme',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (_) {
                            themeProvider.toggleTheme();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // PDF Branding Section
            Text(
              'PDF Branding (Optional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo URL Field
                    Text(
                      'Logo URL',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _logoUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.com/logo.png',
                        prefixIcon: const Icon(Icons.image),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Logo Preview
                    if (_logoUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: Image.network(
                            _logoUrlController.text,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                '❌ Invalid logo URL',
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Company Name Field
                    Text(
                      'Company Name',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _companyNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g., Jumoki Agency LLC',
                        prefixIcon: const Icon(Icons.business),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Company Details Field
                    Text(
                      'Company Details',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _companyDetailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Address, phone, email, etc.',
                        prefixIcon: const Icon(Icons.info),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '📄 Light theme only for professional, printer-friendly PDFs',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingBranding ? null : _savePdfBrandingSettings,
                        icon: _isSavingBranding
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSavingBranding ? 'Saving...' : 'Save PDF Branding'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isPreviewingBranding ? null : _previewBrandingPdf,
                        icon: _isPreviewingBranding
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.preview),
                        label: Text(_isPreviewingBranding ? 'Generating preview...' : 'Preview PDF with Branding'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // About Section
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('App Version'),
                        Text(
                          '1.2.2',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status'),
                        Wrap(
                          spacing: 6,
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.green),
                            Text(
                              'Ready',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Account Actions Section
            Text(
              'Account Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Deleting your account is permanent and cannot be undone.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
