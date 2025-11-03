import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/website_analysis.dart';
import '../theme/spacing.dart';
import '../widgets/process_timeline.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TextEditingController _urlController;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Validate URL for common issues
  /// Returns error message if invalid, null if valid
  /// Auto-prepends https:// if no scheme is present
  String? _validateUrl(String url) {
    if (url.isEmpty) {
      return 'Please enter a website URL';
    }

    // Check for spaces in the URL (especially in domain)
    if (url.contains(' ')) {
      return 'URL cannot contain spaces. Did you mean: ${url.replaceAll(' ', '')}?';
    }

    // Auto-prepend https:// if no scheme is present
    String processedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      processedUrl = 'https://$url';
    }

    // Try to parse as URI to check basic validity
    try {
      final uri = Uri.parse(processedUrl);

      // Check if scheme is valid (should be http or https)
      if (!['http', 'https'].contains(uri.scheme)) {
        return 'URL must use http:// or https:// protocol';
      }

      // Check if host is present
      if (uri.host.isEmpty) {
        return 'Please enter a valid domain (e.g., example.com)';
      }

      // Check for spaces in host (should be caught above but double-check)
      if (uri.host.contains(' ')) {
        return 'Domain name cannot contain spaces';
      }

      // Store the processed URL back to the controller so it displays the full URL
      _urlController.text = processedUrl;

      return null; // Valid URL
    } catch (e) {
      return 'Invalid URL format. Please check and try again.';
    }
  }

  void _generateSummary() async {
    final url = _urlController.text.trim();

    // Validate URL before attempting to process
    final validationError = _validateUrl(url);
    if (validationError != null) {
      setState(() {
        _error = validationError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final summary = await apiService.generateWebslerSummary(url);

      if (mounted) {
        _showSummaryDialog(summary);
        _urlController.clear();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSummaryDialog(WebsiteAnalysis summary) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Summary Generated',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              // URL
              Text(
                'URL',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              SelectableText(
                summary.url,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              if (summary.title != null) ...[
                Text(
                  'Title',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  summary.title!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Summary
              Text(
                'Summary',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                summary.summary,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _upgradeToAudit(summary);
                    },
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Upgrade to Pro Audit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _upgradeToAudit(WebsiteAnalysis summary) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Running WebAudit Pro...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take 1 to 3 minutes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );

    try {
      final apiService = context.read<ApiService>();
      final auditResult = await apiService.upgradeToAudit(summary);

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Audit complete! Check the History tab.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final timelineBottomSpacing = isMobile ? 17.0 : 12.0;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.horizontal,
          vertical: AppSpacing.vertical,
        ).copyWith(top: 88, bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Websler Summary Input Card
            _buildSummaryInputCard(context),
            const SizedBox(height: AppSpacing.sectionGap),

            // How It Works
            _buildHowItWorksSection(context),
            SizedBox(height: timelineBottomSpacing),

            // Motivational Section
            _buildMotivationalSection(context),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryInputCard(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          shadowColor: const Color(0xFF2E68DA).withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF2E68DA),
                  Color(0xFF9018AD),
                ],
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyze Your Website',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      'Get a quick AI-powered summary of any website',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.85),
                          ),
                    ),
                    const Spacer(),
                    if (authService.currentUser != null)
                      Text(
                        authService.currentUser!.email,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.componentGap),

            // URL Input
            TextField(
              controller: _urlController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'Enter website URL (e.g., github.com)',
                prefixIcon: const Icon(Icons.language, color: Color(0xFF9018AD)),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white, width: 2),
                ),
              ),
              onSubmitted: (_) => _generateSummary(),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade400, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateSummary,
                icon: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.summarize, size: 22),
                label: Text(
                  _isLoading ? 'Analyzing...' : 'Generate Summary',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E68DA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    return ProcessTimeline(
      steps: const [
        'Enter your website URL',
        'AI analyzes the content',
        'Get instant summary',
        'Optional: Upgrade to Pro Audit',
      ],
    );
  }

  Widget _buildMotivationalSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 21.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue.shade300
                    : Theme.of(context).primaryColor.withOpacity(0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'Risk it for the Biscuit!',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Fortune favors the hungry; leap first, learn fast, keep swinging until the crumbs turn into whole cakes today.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 75,
                height: 75,
                child: Image.asset(
                  'assets/jumoki_AI_robot_gradient.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
