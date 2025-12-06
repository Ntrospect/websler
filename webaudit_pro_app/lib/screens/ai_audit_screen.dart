import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import '../theme/spacing.dart';
import '../theme/button_styles.dart';
import '../widgets/styled_card.dart';
import 'ai_audit_results_screen.dart';

class AIAuditScreen extends StatefulWidget {
  const AIAuditScreen({Key? key}) : super(key: key);

  @override
  State<AIAuditScreen> createState() => _AIAuditScreenState();
}

class _AIAuditScreenState extends State<AIAuditScreen> {
  late TextEditingController _urlController;
  bool _isLoading = false;
  bool _runLiveTests = false;
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

  String? _validateUrl(String url) {
    if (url.isEmpty) {
      return 'Please enter a website URL';
    }

    if (url.contains(' ')) {
      return 'URL cannot contain spaces';
    }

    String processedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      processedUrl = 'https://$url';
    }

    try {
      final uri = Uri.parse(processedUrl);
      if (uri.host.isEmpty) {
        return 'Please enter a valid domain (e.g., example.com)';
      }
      _urlController.text = processedUrl;
      return null;
    } catch (e) {
      return 'Invalid URL format';
    }
  }

  Future<void> _runAIAudit() async {
    final url = _urlController.text.trim();
    final validationError = _validateUrl(url);

    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                'Running AI Discoverability Audit...',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Evaluating 7 criteria across ${_runLiveTests ? "7+ dimensions" : "all dimensions"}.\nThis may take 1-2 minutes.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.runAIAudit(
        url,
        runLiveTests: _runLiveTests,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          _isLoading = false;
          _urlController.clear();
        });

        // Navigate to results screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AIAuditResultsScreen(auditResult: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthService>(
      builder: (context, themeProvider, authService, _) {
        final isDarkMode = themeProvider.isDarkMode;
        final userEmail = authService.currentUser?.email ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Discoverability Audit'),
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Image.asset(
                  isDarkMode ? 'assets/websler_pro-dark-theme.png' : 'assets/websler_pro.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.horizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _buildHeader(context),
                const SizedBox(height: 24),

                // URL Input Card
                _buildUrlInputCard(context, userEmail),
                const SizedBox(height: 24),

                // How It Works section
                _buildHowItWorks(context),
                const SizedBox(height: 24),

                // 7 Criteria overview
                _buildCriteriaOverview(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.psychology,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Discoverability Audit',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Evaluate how visible your website is to AI search tools like ChatGPT, Claude, and Perplexity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrlInputCard(BuildContext context, String userEmail) {
    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter Website URL',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (userEmail.isNotEmpty)
                Text(
                  userEmail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              hintText: 'https://example.com',
              prefixIcon: const Icon(Icons.link),
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.url,
            onSubmitted: (_) => _runAIAudit(),
          ),
          const SizedBox(height: 16),
          // Live tests toggle
          Row(
            children: [
              Switch(
                value: _runLiveTests,
                onChanged: (value) {
                  setState(() => _runLiveTests = value);
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Run Live LLM Tests',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Query live AI models to test actual visibility (takes longer)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _runAIAudit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology),
              label: Text(
                _isLoading ? 'Running Audit...' : 'Run AI Audit',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: AppButtonStyles.primaryElevatedButton(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(BuildContext context) {
    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildStep(context, '1', 'Website Analysis', 'We crawl your website and extract content, metadata, and structure'),
          _buildStep(context, '2', '7-Criteria Evaluation', 'AI evaluates your site across 7 weighted criteria for discoverability'),
          _buildStep(context, '3', 'Score & Recommendations', 'Get your AI Discoverability Score with prioritized improvements'),
          _buildStep(context, '4', 'Implementation Roadmap', 'Receive a phased action plan with ROI estimates', isLast: true),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String title, String description, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCriteriaOverview(BuildContext context) {
    final criteria = [
      {'name': 'Content Clarity & Parsability', 'weight': '20%', 'icon': Icons.article},
      {'name': 'Answer-Oriented Content', 'weight': '18%', 'icon': Icons.question_answer},
      {'name': 'Technical Accessibility', 'weight': '15%', 'icon': Icons.settings_accessibility},
      {'name': 'Structured Data & Markup', 'weight': '12%', 'icon': Icons.code},
      {'name': 'Information Architecture', 'weight': '10%', 'icon': Icons.account_tree},
      {'name': 'Citation-Worthiness', 'weight': '15%', 'icon': Icons.format_quote},
      {'name': 'Comparative Content', 'weight': '10%', 'icon': Icons.compare_arrows},
    ];

    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7 Evaluation Criteria',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Each criterion is weighted by importance for AI discoverability',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...criteria.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  c['icon'] as IconData,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c['name'] as String,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    c['weight'] as String,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
