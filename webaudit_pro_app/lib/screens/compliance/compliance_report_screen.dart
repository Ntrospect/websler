import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/compliance_audit.dart';
import '../../services/api_service.dart';
import '../../services/theme_provider.dart';

class ComplianceReportScreen extends StatefulWidget {
  final ComplianceAudit compliance;

  const ComplianceReportScreen({
    Key? key,
    required this.compliance,
  }) : super(key: key);

  @override
  State<ComplianceReportScreen> createState() => _ComplianceReportScreenState();
}

class _ComplianceReportScreenState extends State<ComplianceReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.compliance.jurisdictions.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Compliance Report'),
            titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            elevation: 0,
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
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: widget.compliance.jurisdictions.map((jurisdiction) {
                final emoji = ComplianceAudit.getJurisdictionEmoji(jurisdiction);
                final name = ComplianceAudit.getJurisdictionName(jurisdiction);
                return Tab(
                  text: '$emoji $name',
                  icon: const SizedBox.shrink(),
                );
              }).toList(),
            ),
          ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Score Card
              _buildOverallScoreCard(context),
              const SizedBox(height: 32),

              // Critical Issues
              if (widget.compliance.criticalIssues.isNotEmpty) ...[
                _buildCriticalIssuesSection(context),
                const SizedBox(height: 32),
              ],

              // Jurisdiction Tabs Content
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: widget.compliance.jurisdictions.map((jurisdiction) {
                    final score =
                        widget.compliance.jurisdictionScores[jurisdiction];
                    return score != null
                        ? _buildJurisdictionContent(context, score)
                        : const Center(child: Text('No data available'));
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Remediation Roadmap
              _buildRemediationSection(context),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadPdf,
                      icon: _isDownloading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.download),
                      label: Text(
                        _isDownloading ? 'Downloading...' : 'Download PDF',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  Widget _buildOverallScoreCard(BuildContext context) {
    final score = widget.compliance.overallScore;
    final scoreColor = _getScoreColor(score);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(int.parse('FF${scoreColor.replaceFirst('#', '')}',
                  radix: 16)),
              Color(int.parse('FF${scoreColor.replaceFirst('#', '')}',
                      radix: 16))
                  .withOpacity(0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'Overall Compliance Score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$score/100',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.compliance.highestRiskLevel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalIssuesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(
              'Critical Issues',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...widget.compliance.criticalIssues.map((issue) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      issue,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildJurisdictionContent(
    BuildContext context,
    ComplianceJurisdictionScore score,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Jurisdiction Score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ComplianceAudit.getJurisdictionName(score.jurisdiction),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Compliance Score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${score.score}/100',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Critical Issues for this Jurisdiction
          if (score.criticalIssues.isNotEmpty) ...[
            Text(
              'Critical Issues',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...score.criticalIssues.map((issue) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Text(
                    '• $issue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[900],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildRemediationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remediation Roadmap',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...['immediate', 'short_term', 'long_term'].map((period) {
          final actions = widget.compliance.remediationRoadmap[period] as List?;
          final periodLabel = period == 'immediate'
              ? '⚡ Immediate (0-30 days)'
              : period == 'short_term'
              ? '📅 Short-term (1-3 months)'
              : '🔮 Long-term (3-6 months)';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: ExpansionTile(
                title: Text(
                  periodLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (actions != null && actions.isNotEmpty)
                          ...actions.map((action) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      action,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList()
                        else
                          Text(
                            'No actions scheduled for this period',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getScoreColor(int score) {
    if (score >= 80) return '#10B981'; // Green
    if (score >= 60) return '#F59E0B'; // Amber
    if (score >= 40) return '#EA580C'; // Orange
    return '#DC2626'; // Red
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final apiService = context.read<ApiService>();
      final filePath = await apiService.generateCompliancePdf(
        widget.compliance,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ PDF downloaded: ${filePath.split('/').last}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }
}
