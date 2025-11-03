import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/audit_result.dart';
import '../services/theme_provider.dart';
import '../theme/spacing.dart';
import '../theme/button_styles.dart';
import '../widgets/styled_card.dart';
import '../widgets/app_badge.dart';
import 'criterion_detail_screen.dart';
import 'compliance/compliance_selection_screen.dart';

class AuditResultsScreen extends StatefulWidget {
  final AuditResult auditResult;

  const AuditResultsScreen({
    Key? key,
    required this.auditResult,
  }) : super(key: key);

  @override
  State<AuditResultsScreen> createState() => _AuditResultsScreenState();
}

class _AuditResultsScreenState extends State<AuditResultsScreen> {
  late AuditResult _auditResult;
  int _expandedIndex = -1;
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _auditResult = widget.auditResult;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;

        return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Audit Results'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        elevation: 0,
        backgroundColor: _isScrolled
            ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8)
            : Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
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
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.horizontal, 80, AppSpacing.horizontal, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Website Info
              _buildWebsiteInfo(context),
              const SizedBox(height: AppSpacing.sectionGap),

              // Overall Score Display
              _buildOverallScoreDisplay(context),
              const SizedBox(height: AppSpacing.sectionGap),

              // 10 Criterion Scores Grid
              _buildScoresGrid(context),
              const SizedBox(height: AppSpacing.sectionGap),
              Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
              const SizedBox(height: AppSpacing.sectionGap),

              // Key Strengths
              _buildSection(
                context,
                'Key Strengths',
                Icons.check_circle_outline,
                Colors.green,
                _auditResult.keyStrengths,
              ),
              const SizedBox(height: AppSpacing.componentGap),
              Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
              const SizedBox(height: AppSpacing.sectionGap),

              // Critical Issues
              _buildSection(
                context,
                'Critical Issues',
                Icons.warning_outlined,
                Colors.red,
                _auditResult.criticalIssues,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
              const SizedBox(height: AppSpacing.sectionGap),

              // Priority Recommendations
              _buildRecommendationsSection(context),
              const SizedBox(height: AppSpacing.sectionGap),

              // Download PDF Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadAuditPdf(context),
                  icon: const Icon(Icons.file_download_outlined),
                  label: const Text(
                    'Download PDF Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: AppButtonStyles.primaryElevatedButton(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Compliance Audit Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToComplianceAudit(),
                  icon: const Icon(Icons.gavel),
                  label: const Text(
                    'Run Compliance Audit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  Widget _buildWebsiteInfo(BuildContext context) {
    return StyledCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Website',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _auditResult.websiteName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.componentGap),
          Text(
            'Audit Date',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_auditResult.formattedDate} at ${_auditResult.formattedTime}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScoreDisplay(BuildContext context) {
    final score = _auditResult.overallScore;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    late Color scoreColor, gradientColor;
    late String scoreStatus;

    if (score >= 7.5) {
      scoreColor = Colors.green;
      gradientColor = Colors.green.shade700;
      scoreStatus = 'Excellent';
    } else if (score >= 5.0) {
      scoreColor = Colors.orange;
      gradientColor = Colors.orange.shade700;
      scoreStatus = 'Good';
    } else {
      scoreColor = Colors.red;
      gradientColor = Colors.red.shade700;
      scoreStatus = 'Needs Work';
    }

    final scoreContainer = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scoreColor, gradientColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isDesktop
          ? Row(
              children: [
                const SizedBox(width: 140),
                const Spacer(flex: 1),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Overall Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${score.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      scoreStatus,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.95),
                            letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    'assets/websler-logo-robot-WHITE.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Score',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${score.toStringAsFixed(1)}/10',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        scoreStatus,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    'assets/websler-logo-robot-WHITE.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
    );

    return scoreContainer;
  }

  Widget _buildScoresGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Text(
            '10-Point Evaluation',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
            ),
          ),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: 170,
          ),
          itemCount: _auditResult.scores.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final entries = _auditResult.scores.entries.toList();
            final criterion = entries[index].key;
            final score = entries[index].value;
            return _buildScoreCard(context, criterion, score);
          },
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, String criterion, double score) {
    late Color bgColor, textColor, gradientColor;

    if (score >= 8) {
      bgColor = Colors.green.withOpacity(0.08);
      textColor = Colors.green;
      gradientColor = Colors.green.shade600;
    } else if (score >= 6) {
      bgColor = Colors.orange.withOpacity(0.08);
      textColor = Colors.orange;
      gradientColor = Colors.orange.shade600;
    } else {
      bgColor = Colors.red.withOpacity(0.08);
      textColor = Colors.red;
      gradientColor = Colors.red.shade600;
    }

    return _ScoreCardWithHover(
      criterion: criterion,
      score: score,
      bgColor: bgColor,
      textColor: textColor,
      gradientColor: gradientColor,
      onTap: () => _navigateToCriterionDetail(context, criterion, score),
    );
  }

  void _navigateToCriterionDetail(BuildContext context, String criterion, double score) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriterionDetailScreen(
          criterion: criterion,
          score: score,
          overallScore: _auditResult.overallScore,
          recommendations: _auditResult.priorityRecommendations,
          allScores: _auditResult.scores,
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.componentGap),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        item,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    final recommendations = _auditResult.priorityRecommendations.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Top Recommendations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.blue,
                      letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.componentGap),
        ...List.generate(
          recommendations.length,
          (index) {
            final rec = recommendations[index];
            final isExpanded = _expandedIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                margin: EdgeInsets.zero,
                child: ExpansionTile(
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedIndex = expanded ? index : -1;
                    });
                  },
                  initiallyExpanded: isExpanded,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    '${index + 1}. ${rec.criterion}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: !isExpanded ? Text(
                    rec.recommendation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ) : null,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            rec.recommendation,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.6,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: PriorityBadge(priority: rec.priority),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _navigateToComplianceAudit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplianceSelectionScreen(
          auditId: _auditResult.id,
          auditUrl: _auditResult.url,
        ),
      ),
    );
  }

  Future<void> _downloadAuditPdf(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final apiService = Provider.of<ApiService>(context, listen: false);

      // Generate PDF using the existing audit data
      await apiService.generatePdf(
        _auditResult.id,
        isAudit: true,
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF downloaded successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error downloading PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Score card with interactive hover state
class _ScoreCardWithHover extends StatefulWidget {
  final String criterion;
  final double score;
  final Color bgColor;
  final Color textColor;
  final Color gradientColor;
  final VoidCallback onTap;

  const _ScoreCardWithHover({
    required this.criterion,
    required this.score,
    required this.bgColor,
    required this.textColor,
    required this.gradientColor,
    required this.onTap,
  });

  @override
  State<_ScoreCardWithHover> createState() => _ScoreCardWithHoverState();
}

class _ScoreCardWithHoverState extends State<_ScoreCardWithHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -4 : 0.0),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.withOpacity(_isHovered ? 0.7 : 0.5),
            width: 1.5,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.textColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.textColor.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.score.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: widget.textColor,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.criterion,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 13,
                          color: widget.textColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedOpacity(
                    opacity: _isHovered ? 1.0 : 0.6,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: widget.textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
