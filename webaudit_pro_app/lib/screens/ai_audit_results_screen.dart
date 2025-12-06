import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_audit_result.dart';
import '../services/api_service.dart';
import '../services/theme_provider.dart';
import '../theme/spacing.dart';
import '../theme/button_styles.dart';
import '../widgets/styled_card.dart';
import '../widgets/app_badge.dart';

class AIAuditResultsScreen extends StatefulWidget {
  final AIAuditResult auditResult;

  const AIAuditResultsScreen({
    Key? key,
    required this.auditResult,
  }) : super(key: key);

  @override
  State<AIAuditResultsScreen> createState() => _AIAuditResultsScreenState();
}

class _AIAuditResultsScreenState extends State<AIAuditResultsScreen> {
  late AIAuditResult _auditResult;
  late ScrollController _scrollController;
  bool _isScrolled = false;
  int _expandedRecommendationIndex = -1;
  int _expandedRoadmapIndex = -1;

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

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getCriterionScoreColor(double score) {
    if (score >= 7) return Colors.green;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  String _getRoiColor(String roi) {
    switch (roi) {
      case 'High':
        return 'green';
      case 'Medium':
        return 'orange';
      case 'Low':
        return 'red';
      default:
        return 'grey';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('AI Discoverability Audit'),
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
              padding: EdgeInsets.fromLTRB(AppSpacing.horizontal, 100, AppSpacing.horizontal, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Website Info
                  _buildWebsiteInfo(context),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Overall Score & LLM Confidence
                  _buildScoreCards(context),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Primary Identity
                  _buildPrimaryIdentity(context),
                  const SizedBox(height: AppSpacing.sectionGap),

                  Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // 7 Criteria Scores
                  _buildCriteriaScores(context),
                  const SizedBox(height: AppSpacing.sectionGap),

                  Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Key Strengths
                  if (_auditResult.keyStrengths.isNotEmpty) ...[
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
                  ],

                  // Critical Blockers
                  if (_auditResult.criticalBlockers.isNotEmpty) ...[
                    _buildSection(
                      context,
                      'Critical Blockers',
                      Icons.warning_amber_outlined,
                      Colors.red,
                      _auditResult.criticalBlockers,
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],

                  // Recommendations
                  _buildRecommendationsSection(context),
                  const SizedBox(height: AppSpacing.sectionGap),

                  Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Implementation Roadmap
                  if (_auditResult.implementationRoadmap != null) ...[
                    _buildRoadmapSection(context),
                    const SizedBox(height: AppSpacing.sectionGap),
                    Divider(color: Colors.grey.withOpacity(0.5), thickness: 1),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],

                  // Predicted Prompts
                  _buildPredictedPrompts(context),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Download PDF Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadPdf(context),
                      icon: const Icon(Icons.file_download_outlined),
                      label: const Text(
                        'Download AI Audit Report',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: AppButtonStyles.primaryElevatedButton(context),
                    ),
                  ),
                  const SizedBox(height: 32),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _auditResult.websiteName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _auditResult.url,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Audited: ${_auditResult.formattedDate} at ${_auditResult.formattedTime}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCards(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 600;

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _buildOverallScoreCard(context)),
          const SizedBox(width: 16),
          Expanded(child: _buildConfidenceCard(context)),
        ],
      );
    }

    return Column(
      children: [
        _buildOverallScoreCard(context),
        const SizedBox(height: 16),
        _buildConfidenceCard(context),
      ],
    );
  }

  Widget _buildOverallScoreCard(BuildContext context) {
    final score = _auditResult.overallScore;
    final color = _getScoreColor(score);

    return StyledCard(
      child: Column(
        children: [
          Text(
            'AI Discoverability Score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '/100',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _auditResult.getScoreStatus(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(BuildContext context) {
    final confidence = _auditResult.llmConfidenceScore;
    final color = confidence >= 70 ? Colors.green : confidence >= 50 ? Colors.orange : Colors.red;

    return StyledCard(
      child: Column(
        children: [
          Text(
            'LLM Confidence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$confidence',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_auditResult.getConfidenceLevel()} Confidence',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryIdentity(BuildContext context) {
    return StyledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                'AI Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _auditResult.primaryIdentity,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaScores(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '7-Criteria Evaluation',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._auditResult.scores.entries.map((entry) {
          final score = entry.value;
          return _buildCriterionCard(context, score);
        }).toList(),
      ],
    );
  }

  Widget _buildCriterionCard(BuildContext context, AICriterionScore score) {
    final color = _getCriterionScoreColor(score.score);
    final weightPercent = (score.weight * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    score.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${score.score.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$weightPercent%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score.score / 10,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              score.observation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (score.findings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...score.findings.take(2).map((finding) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('- ', style: TextStyle(color: Colors.grey)),
                    Expanded(
                      child: Text(
                        finding,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
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
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                title.contains('Strength') ? Icons.add_circle : Icons.remove_circle,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildRecommendationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              'Prioritized Recommendations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._auditResult.recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final rec = entry.value;
          final isExpanded = _expandedRecommendationIndex == index;

          Color roiColor;
          switch (rec.roiAssessment) {
            case 'High':
              roiColor = Colors.green;
              break;
            case 'Medium':
              roiColor = Colors.orange;
              break;
            default:
              roiColor = Colors.red;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StyledCard(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedRecommendationIndex = isExpanded ? -1 : index;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${rec.priority}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                rec.criterion,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppBadge(
                          label: '${rec.roiAssessment} ROI',
                          backgroundColor: roiColor.withOpacity(0.1),
                          textColor: roiColor,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        rec.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildInfoChip(context, 'Cost', rec.costOfImplementation, Colors.blue),
                          const SizedBox(width: 8),
                          _buildInfoChip(context, 'Timeline', rec.timeline, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Expected: ${rec.expectedImprovement}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapSection(BuildContext context) {
    final roadmap = _auditResult.implementationRoadmap!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Implementation Roadmap',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total Expected Improvement: ${roadmap.totalImprovement}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ...roadmap.phases.asMap().entries.map((entry) {
          final index = entry.key;
          final phase = entry.value;
          final isExpanded = _expandedRoadmapIndex == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: StyledCard(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expandedRoadmapIndex = isExpanded ? -1 : index;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                phase.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                phase.timeframe,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Tasks:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...phase.tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_box_outline_blank, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(task)),
                          ],
                        ),
                      )).toList(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Expected Improvement: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            phase.expectedScoreImprovement,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Effort: ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            phase.totalEffort,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPredictedPrompts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Theme.of(context).primaryColor, size: 24),
            const SizedBox(width: 8),
            Text(
              'Predicted Prompts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Questions users might ask LLMs that this site could answer:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ..._auditResult.predictedPrompts.map((prompt) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prompt,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  Future<void> _downloadPdf(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(content: Text('Generating PDF report...')),
      );

      final apiService = context.read<ApiService>();
      final filepath = await apiService.generateAIAuditPdf(_auditResult.id);

      if (filepath.isEmpty) {
        // Web - opened in new tab
        messenger.showSnackBar(
          const SnackBar(content: Text('PDF opened in new tab')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('PDF saved to: $filepath')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
