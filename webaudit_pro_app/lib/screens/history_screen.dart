import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_provider.dart';
import '../models/website_analysis.dart';
import '../models/compliance_audit.dart';
import '../theme/spacing.dart';
import '../widgets/styled_card.dart';
import 'audit_results_screen.dart';
import 'compliance/compliance_report_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isScrolled = false;
  List<WebsiteAnalysis> _history = [];
  List<ComplianceAudit> _complianceHistory = [];
  late ScrollController _scrollController;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHistory();
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 10) {
      if (!_isScrolled) {
        setState(() => _isScrolled = true);
      }
    } else {
      if (_isScrolled) {
        setState(() => _isScrolled = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<ApiService>();

      // Load both summaries/audits and compliance audits
      final unifiedHistory = await apiService.getUnifiedHistory(limit: 50);
      final complianceAudits = await apiService.getComplianceHistory(limit: 50);

      if (mounted) {
        setState(() {
          _history = unifiedHistory;
          _complianceHistory = complianceAudits;
        });
      }
    } catch (e) {
      if (mounted) {
        // Only show error if it's not a connection error (backend not running)
        // Connection errors are expected when backend is not running - just show empty state
        final errorStr = e.toString().toLowerCase();
        if (!errorStr.contains('refused') && !errorStr.contains('connection') && !errorStr.contains('localhost')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading history: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _history = [];
          _complianceHistory = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteAnalysis(WebsiteAnalysis analysis) async {
    try {
      await context.read<ApiService>().deleteAnalysisUnified(analysis);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis deleted')),
        );
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCompliance(ComplianceAudit compliance) async {
    try {
      await context.read<ApiService>().deleteComplianceAudit(compliance.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compliance audit deleted')),
        );
        _loadHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

        // Navigate to audit results
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AuditResultsScreen(auditResult: auditResult.auditResult!),
          ),
        ).then((_) {
          _loadHistory();
        });
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

  void _viewAudit(WebsiteAnalysis analysis) {
    if (analysis.isAudit && analysis.auditResult != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AuditResultsScreen(auditResult: analysis.auditResult!),
        ),
      );
    }
  }

  // Helper methods to get filtered lists
  List<WebsiteAnalysis> get _summaries =>
      _history.where((a) => a.isSummary).toList();

  List<WebsiteAnalysis> get _audits =>
      _history.where((a) => a.isAudit).toList();

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

        return Consumer<AuthService>(
          builder: (context, authService, _) {
            return Scaffold(
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Analysis History'),
                    if (authService.currentUser != null)
                      Text(
                        authService.currentUser!.email,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
                titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                elevation: 0,
                backgroundColor: _isScrolled ? scrolledBgColor : bgColor,
                surfaceTintColor: bgColor,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(110),
                  child: Column(
                    children: [
                      Divider(height: 1, color: Colors.grey[300]),
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: SizedBox(
                          height: 90,
                          child: TabBar(
                            controller: _tabController,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                          tabs: [
                            _buildTab(
                              label: 'Summary',
                              icon: Icons.summarize,
                              count: _summaries.length,
                              color: Colors.blue,
                            ),
                            _buildTab(
                              label: 'WebAudit Pro',
                              icon: Icons.assessment,
                              count: _audits.length,
                              color: Colors.green,
                            ),
                            _buildTab(
                              label: 'Compliance',
                              icon: Icons.gavel,
                              count: _complianceHistory.length,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              body: _isLoading && _history.isEmpty && _complianceHistory.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Summary Tab
                        _buildTabContent(
                          isEmpty: _summaries.isEmpty,
                          isLoading: _isLoading,
                          emptyTitle: 'No Summaries Yet',
                          emptyMessage: 'Create quick summaries of websites',
                          emptyIcon: Icons.summarize,
                          onRefresh: _loadHistory,
                          itemCount: _summaries.length,
                          itemBuilder: (context, index) => _buildHistoryCard(_summaries[index]),
                        ),
                        // WebAudit Pro Tab
                        _buildTabContent(
                          isEmpty: _audits.isEmpty,
                          isLoading: _isLoading,
                          emptyTitle: 'No Audits Yet',
                          emptyMessage: 'Run comprehensive 10-point audits',
                          emptyIcon: Icons.assessment,
                          onRefresh: _loadHistory,
                          itemCount: _audits.length,
                          itemBuilder: (context, index) => _buildHistoryCard(_audits[index]),
                        ),
                        // Compliance Tab
                        _buildTabContent(
                          isEmpty: _complianceHistory.isEmpty,
                          isLoading: _isLoading,
                          emptyTitle: 'No Compliance Reports Yet',
                          emptyMessage: 'Analyze legal and regulatory compliance',
                          emptyIcon: Icons.gavel,
                          onRefresh: _loadHistory,
                          itemCount: _complianceHistory.length,
                          itemBuilder: (context, index) => _buildComplianceCard(_complianceHistory[index]),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required bool isEmpty,
    required bool isLoading,
    required String emptyTitle,
    required String emptyMessage,
    required IconData emptyIcon,
    required VoidCallback onRefresh,
    required int itemCount,
    required Widget? Function(BuildContext, int) itemBuilder,
  }) {
    if (isEmpty && !isLoading) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.only(top: 16),
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    emptyIcon,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 56, bottom: 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => itemBuilder(context, index) ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildHistoryCard(WebsiteAnalysis analysis) {
    final color = analysis.isSummary
        ? Colors.blue
        : (analysis.auditResult?.overallScore ?? 0) >= 7.5
            ? Colors.green
            : (analysis.auditResult?.overallScore ?? 0) >= 5
                ? Colors.orange
                : Colors.red;

    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  analysis.isSummary ? Icons.summarize : Icons.assessment,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Raleway',
                            fontSize: 18,
                          ),
                    ),
                    Text(
                      analysis.formattedDateTime,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (analysis.isAudit && analysis.overallScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${analysis.overallScore!.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // URL
          Text(
            'URL',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SelectableText(
            analysis.url,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),

          // Summary
          Text(
            analysis.isSummary ? 'Summary' : 'Overall Result',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            analysis.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (analysis.isSummary)
                OutlinedButton(
                  onPressed: () => _upgradeToAudit(analysis),
                  child: const Text('Upgrade to Pro'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => _viewAudit(analysis),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('View Audit'),
                ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteAnalysis(analysis);
                  }
                },
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ],
        ),
      );
  }

  Widget _buildComplianceCard(ComplianceAudit compliance) {
    final scoreColor = compliance.overallScore >= 80
        ? Colors.green
        : compliance.overallScore >= 60
            ? Colors.orange
            : Colors.red;

    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compliance Report',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      compliance.url,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${compliance.overallScore}/100',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Jurisdictions
          Wrap(
            spacing: 8,
            children: compliance.jurisdictions.map((jurisdiction) {
              return Chip(
                label: Text(
                  '${ComplianceAudit.getJurisdictionEmoji(jurisdiction)} ${ComplianceAudit.getJurisdictionName(jurisdiction)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                side: BorderSide(color: Colors.grey[300]!),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // Date and Risk Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                compliance.createdAt.split('T')[0],
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  compliance.highestRiskLevel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _deleteCompliance(compliance),
                child: const Text('Delete'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComplianceReportScreen(
                        compliance: compliance,
                      ),
                    ),
                  ).then((_) => _loadHistory());
                },
                child: const Text('View Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
