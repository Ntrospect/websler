import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/compliance_audit.dart';
import '../../services/api_service.dart';
import '../../services/theme_provider.dart';
import 'compliance_report_screen.dart';

class ComplianceSelectionScreen extends StatefulWidget {
  final String? auditId;
  final String? auditUrl;

  const ComplianceSelectionScreen({
    Key? key,
    this.auditId,
    this.auditUrl,
  }) : super(key: key);

  @override
  State<ComplianceSelectionScreen> createState() =>
      _ComplianceSelectionScreenState();
}

class _ComplianceSelectionScreenState extends State<ComplianceSelectionScreen> {
  late Map<String, bool> selectedJurisdictions = {
    'AU': true,
    'NZ': true,
    'GDPR': false,
    'CCPA': false,
  };

  bool _isLoading = false;
  String? _error;

  final Map<String, String> jurisdictionDescriptions = {
    'AU': 'Australian Consumer Law, Privacy Act 1988, Spam Act 2003, AANA Code of Ethics',
    'NZ': 'Consumer Guarantees Act 1993, Privacy Act 2020, Fair Trading Act 1986',
    'GDPR': 'GDPR compliance for European Union data subjects and regulations',
    'CCPA': 'California Consumer Privacy Act and California Privacy Rights Act',
  };

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Compliance Audit'),
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
              // Header
              Text(
                'Select Jurisdictions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose which legal jurisdictions you want to evaluate compliance against.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Jurisdiction Cards
              ..._buildJurisdictionCards(context),

              const SizedBox(height: 32),

              // Error Message
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _runComplianceAudit,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.gavel),
                      label: Text(_isLoading ? 'Running Audit...' : 'Run Compliance Audit'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Compliance audits analyze your website for legal and regulatory compliance. The process typically takes 2-5 minutes.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  List<Widget> _buildJurisdictionCards(BuildContext context) {
    return selectedJurisdictions.keys.map((jurisdiction) {
      final isSelected = selectedJurisdictions[jurisdiction]!;
      final description = jurisdictionDescriptions[jurisdiction]!;
      final emoji = ComplianceAudit.getJurisdictionEmoji(jurisdiction);
      final name = ComplianceAudit.getJurisdictionName(jurisdiction);

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.withOpacity(0.5)
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedJurisdictions[jurisdiction] = !isSelected;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        selectedJurisdictions[jurisdiction] = value ?? false;
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 12),

                  // Jurisdiction Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
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
    }).toList();
  }

  Future<void> _runComplianceAudit() async {
    // Validate at least one jurisdiction is selected
    if (!selectedJurisdictions.values.any((selected) => selected)) {
      setState(() {
        _error = 'Please select at least one jurisdiction';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final selectedJuris = selectedJurisdictions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Running Compliance Audit...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take 2-5 minutes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Run the compliance audit
      final compliance = await apiService.generateComplianceAudit(
        widget.auditUrl ?? '',
        jurisdictions: selectedJuris,
        auditId: widget.auditId,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to compliance report screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ComplianceReportScreen(
              compliance: compliance,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if still open
        Navigator.pop(context);

        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }
}
