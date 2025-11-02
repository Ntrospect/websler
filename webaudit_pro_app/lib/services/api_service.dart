import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import '../models/analysis.dart';
import '../models/audit_result.dart';
import '../models/website_analysis.dart';
import '../models/compliance_audit.dart';
import '../utils/env_loader.dart';
import '../utils/pdf_utils.dart';
import '../config/environment.dart';

class ApiService extends ChangeNotifier {
  final SharedPreferences _prefs;
  late String _apiUrl;
  String? _authToken;

  static const String _apiUrlKey = 'api_url';

  ApiService(this._prefs) {
    _apiUrl = _prefs.getString(_apiUrlKey) ?? EnvConfig.getApiUrl();
    _authToken = _prefs.getString('auth_token');
  }

  String get apiUrl => _apiUrl;
  String? get authToken => _authToken;

  void setApiUrl(String url) {
    _apiUrl = url;
    _prefs.setString(_apiUrlKey, url);
    notifyListeners();
  }

  /// Set auth token (called by AuthService when user logs in)
  void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      final preview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
      print('🔑 ApiService: Auth token SET: $preview');
      _prefs.setString('auth_token', token);
    } else {
      print('🔑 ApiService: Auth token CLEARED');
      _prefs.remove('auth_token');
    }
    notifyListeners();
  }

  /// Build headers with auth token if available
  Map<String, String> _buildHeaders({Map<String, String>? customHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?customHeaders,
    };

    if (_authToken != null) {
      final preview = _authToken!.length > 20 ? '${_authToken!.substring(0, 20)}...' : _authToken!;
      print('📤 ApiService: Including Authorization header: Bearer $preview');
      headers['Authorization'] = 'Bearer $_authToken';
    } else {
      print('⚠️ ApiService: NO AUTH TOKEN - Authorization header not included!');
    }

    return headers;
  }

  Future<Analysis> analyzeUrl(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/api/analyze'),
        headers: _buildHeaders(),
        body: jsonEncode({'url': url}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return Analysis.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to analyze URL: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analyzing URL: $e');
    }
  }

  Future<List<Analysis>> getHistory({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/history?limit=$limit'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analyses = (data['analyses'] as List)
            .map((item) => Analysis.fromJson(item))
            .toList();
        return analyses;
      } else {
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }

  Future<Analysis> getAnalysis(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/analyses/$id'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Analysis.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get analysis: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching analysis: $e');
    }
  }

  /// Generate PDF from a summary analysis (light theme only for printing)
  /// Returns: filepath (desktop/mobile) or empty string (web, opens in new tab)
  Future<String> generatePdf(
    String analysisId, {
    String? logoUrl,
    String? companyName,
    String? companyDetails,
    String template = 'jumoki',
  }) async {
    try {
      debugPrint('📄 Generating summary PDF (light theme)');

      final response = await http.post(
        Uri.parse('$_apiUrl/api/pdf'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'analysis_id': analysisId,
          'logo_url': logoUrl,
          'company_name': companyName,
          'company_details': companyDetails,
          'template': template,
          'theme': 'light',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final filename = 'weblser-analysis-${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Handle web platform - open in new tab
        if (kIsWeb) {
          debugPrint('🌐 Opening PDF in new tab (web)');
          final success = await PdfUtils.openPdfInNewTab(response.bodyBytes, filename);
          if (!success) {
            throw Exception('Failed to open PDF in new tab');
          }
          return ''; // Return empty string for web (no file path)
        }

        // Handle mobile/desktop - save to file
        debugPrint('💾 Saving PDF to file (mobile/desktop)');
        final Directory? downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          throw Exception('Could not access Downloads directory');
        }

        final String filepath = '${downloadsDir.path}/$filename';
        final File file = File(filepath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ PDF saved to: $filepath');

        return filepath;
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      throw Exception('Error generating PDF: $e');
    }
  }

  Future<void> deleteAnalysis(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/api/analyses/$id'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete analysis: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting analysis: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      debugPrint('🗑️ Clearing Weblser summary history...');
      final response = await http.delete(
        Uri.parse('$_apiUrl/api/history'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      debugPrint('📊 Clear history response: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('❌ Clear history failed: ${response.body}');
        throw Exception('Failed to clear history: ${response.statusCode} - ${response.body}');
      }
      debugPrint('✅ Weblser history cleared successfully');
    } catch (e) {
      debugPrint('🔴 Error clearing history: $e');
      throw Exception('Error clearing history: $e');
    }
  }

  // ==================== WebAudit Pro - Audit Methods ====================

  /// Run a comprehensive 10-point audit on a website
  Future<AuditResult> auditWebsite(
    String url, {
    int timeout = 120,
    bool deepScan = true,
  }) async {
    try {
      debugPrint('🔍 Starting audit for URL: $url');
      debugPrint('📡 API URL: $_apiUrl/api/audit/analyze');

      final response = await http.post(
        Uri.parse('$_apiUrl/api/audit/analyze'),
        headers: _buildHeaders(),
        body: jsonEncode({
          'url': url,
          'timeout': timeout,
          'deep_scan': deepScan,
        }),
      ).timeout(Duration(seconds: timeout + 60));

      debugPrint('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Audit successful');
        return AuditResult.fromJson(jsonDecode(response.body));
      } else {
        final errorBody = response.body;
        debugPrint('❌ Server error: ${response.statusCode}');
        debugPrint('📝 Response body: $errorBody');
        throw Exception('Server error ${response.statusCode}: $errorBody');
      }
    } on TimeoutException catch (e) {
      debugPrint('⏱️ Request timeout: $e');
      throw Exception('Request timeout - audit took too long. Please try again.');
    } catch (e) {
      debugPrint('🔴 Error auditing website: $e');
      throw Exception('Error auditing website: $e');
    }
  }

  /// Get a specific audit result by ID
  Future<AuditResult> getAudit(String auditId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/audit/$auditId'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return AuditResult.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get audit: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching audit: $e');
    }
  }

  /// Get audit history
  Future<List<AuditResult>> getAuditHistory({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/audit/history/list?limit=$limit'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audits = (data['audits'] as List)
            .map((item) => AuditResult.fromJson(item as Map<String, dynamic>))
            .toList();
        return audits;
      } else {
        throw Exception('Failed to get audit history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching audit history: $e');
    }
  }

  /// Generate PDF report for an audit
  /// documentType: "audit-report", "improvement-plan", or "partnership-proposal"
  /// Returns: filepath (desktop/mobile) or empty string (web, opens in new tab)
  Future<String> generateAuditPdf(
    String auditId,
    String documentType, {
    String? clientName,
    String? logoUrl,
    String? companyName,
    String? companyDetails,
  }) async {
    try {
      // Validate document type
      const validTypes = ['audit-report', 'improvement-plan', 'partnership-proposal'];
      if (!validTypes.contains(documentType)) {
        throw Exception('Invalid document type: $documentType');
      }

      debugPrint('📄 Generating PDF: $documentType');

      // Build request body - only include non-null fields
      final Map<String, dynamic> requestBody = {};
      if (clientName != null) requestBody['client_name'] = clientName;
      if (companyName != null) requestBody['company_name'] = companyName;
      if (companyDetails != null) requestBody['company_details'] = companyDetails;

      final response = await http.post(
        Uri.parse('$_apiUrl/api/audit/generate-pdf/$auditId/$documentType'),
        headers: _buildHeaders(),
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final filename = 'webaudit-$documentType-${DateTime.now().millisecondsSinceEpoch}.pdf';

        // Handle web platform - open in new tab
        if (kIsWeb) {
          debugPrint('🌐 Opening PDF in new tab (web)');
          final success = await PdfUtils.openPdfInNewTab(response.bodyBytes, filename);
          if (!success) {
            throw Exception('Failed to open PDF in new tab');
          }
          return ''; // Return empty string for web (no file path)
        }

        // Handle mobile/desktop - save to file
        debugPrint('💾 Saving PDF to file (mobile/desktop)');
        final Directory? downloadsDir = await getDownloadsDirectory();
        if (downloadsDir == null) {
          throw Exception('Could not access Downloads directory');
        }

        final String filepath = '${downloadsDir.path}/$filename';
        final File file = File(filepath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('✅ PDF saved to: $filepath');

        return filepath;
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error generating PDF: $e');
      throw Exception('Error generating PDF: $e');
    }
  }

  /// Delete an audit from history
  Future<void> deleteAudit(String auditId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/api/audit/$auditId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete audit: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting audit: $e');
    }
  }

  /// Clear all audit history
  Future<void> clearAuditHistory() async {
    try {
      try {
        debugPrint('🗑️ Clearing WebAudit Pro audit history...');

        // Defensive null checks with environment-aware fallback
        final baseUrl = _apiUrl ?? (AppConfig.environment == Environment.staging
            ? 'https://140.99.254.83'
            : 'https://api.websler.pro');
        final headers = _buildHeaders() ?? {'Content-Type': 'application/json'};
        final url = '$baseUrl/api/audit/history/clear';

        debugPrint('📍 Clearing audits from: $url');

        final uri = Uri.parse(url);
        final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 10));

        debugPrint('📊 Clear audit history response: ${response.statusCode}');
        if (response.statusCode != 200) {
          throw Exception('Server returned ${response.statusCode}: ${response.body}');
        }
        debugPrint('✅ WebAudit Pro history cleared successfully');
      } catch (innerError) {
        debugPrint('⚠️ Inner error in clearAuditHistory: $innerError');
        rethrow;
      }
    } catch (e) {
      debugPrint('🔴 Error clearing audit history: $e');
      throw Exception('Error clearing audit history: $e');
    }
  }

  // ==================== Unified History Methods ====================

  /// Generate a Weblser summary and return as unified WebsiteAnalysis
  Future<WebsiteAnalysis> generateWebslerSummary(String url) async {
    try {
      final analysis = await analyzeUrl(url);
      return WebsiteAnalysis.fromSummaryJson(analysis.toJson());
    } catch (e) {
      throw Exception('Error generating summary: $e');
    }
  }

  /// Get unified history combining both summaries and audits
  /// Returns chronologically sorted list (newest first)
  Future<List<WebsiteAnalysis>> getUnifiedHistory({int limit = 100}) async {
    try {
      // Get both summaries and audits in parallel
      final summaryFuture = getHistory(limit: limit);
      final auditFuture = getAuditHistory(limit: limit);

      final summaries = await summaryFuture;
      final audits = await auditFuture;

      // Convert to unified model
      final unifiedList = <WebsiteAnalysis>[
        ...summaries.map((s) => WebsiteAnalysis.fromSummaryJson(s.toJson())),
        ...audits.map((a) => WebsiteAnalysis.fromAuditJson(a.toJson())),
      ];

      // Sort by created_at descending (newest first)
      unifiedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Return limited list
      return unifiedList.take(limit).toList();
    } catch (e) {
      throw Exception('Error fetching unified history: $e');
    }
  }

  /// Get only summaries from unified history
  Future<List<WebsiteAnalysis>> getSummaryHistory({int limit = 100}) async {
    try {
      final summaries = await getHistory(limit: limit);
      return summaries
          .map((s) => WebsiteAnalysis.fromSummaryJson(s.toJson()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching summary history: $e');
    }
  }

  /// Get only audits from unified history
  Future<List<WebsiteAnalysis>> getAuditHistoryAsUnified({int limit = 100}) async {
    try {
      final audits = await getAuditHistory(limit: limit);
      return audits
          .map((a) => WebsiteAnalysis.fromAuditJson(a.toJson()))
          .toList();
    } catch (e) {
      throw Exception('Error fetching audit history: $e');
    }
  }

  /// Delete a unified analysis (works for both summaries and audits)
  Future<void> deleteAnalysisUnified(WebsiteAnalysis analysis) async {
    try {
      if (analysis.isSummary) {
        await deleteAnalysis(analysis.id);
      } else {
        await deleteAudit(analysis.id);
      }
    } catch (e) {
      throw Exception('Error deleting analysis: $e');
    }
  }

  /// Generate PDF from unified analysis (works for both summaries and audits)
  Future<String> generatePdfUnified(
    WebsiteAnalysis analysis, {
    String documentType = 'audit-report', // For audits
    String? clientName,
    String? logoUrl,
    String? companyName,
    String? companyDetails,
  }) async {
    try {
      if (analysis.isSummary) {
        // For summaries, use the weblser PDF generation
        return await generatePdf(analysis.id,
            logoUrl: logoUrl, companyName: companyName, companyDetails: companyDetails);
      } else {
        // For audits, use the audit PDF generation
        return await generateAuditPdf(
          analysis.id,
          documentType,
          clientName: clientName,
          logoUrl: logoUrl,
          companyName: companyName,
          companyDetails: companyDetails,
        );
      }
    } catch (e) {
      throw Exception('Error generating PDF: $e');
    }
  }

  /// Upgrade a summary to a full audit (run audit on the same URL)
  Future<WebsiteAnalysis> upgradeToAudit(
    WebsiteAnalysis summary, {
    int timeout = 60,
    bool deepScan = true,
  }) async {
    if (!summary.isSummary) {
      throw Exception('Can only upgrade summaries to audits');
    }

    try {
      final auditResult = await auditWebsite(
        summary.url,
        timeout: timeout,
        deepScan: deepScan,
      );

      return WebsiteAnalysis.fromAuditJson(
        auditResult.toJson(),
        linkedSummaryId: summary.id,
      );
    } catch (e) {
      throw Exception('Error upgrading to audit: $e');
    }
  }

  // ==================== Compliance Audit Methods ====================

  /// Generate a compliance audit for a website
  Future<ComplianceAudit> generateComplianceAudit(
    String url, {
    List<String> jurisdictions = const ['AU', 'NZ'],
    String? auditId,
    int timeout = 360,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final request = ComplianceAuditRequest(
        url: url,
        jurisdictions: jurisdictions,
        timeout: timeout,
        auditId: auditId,
      );

      final response = await http
          .post(
            Uri.parse('$_apiUrl/api/compliance-audit'),
            headers: _buildHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(Duration(seconds: timeout + 5));

      if (response.statusCode != 200) {
        throw Exception('Compliance audit failed: ${response.body}');
      }

      final jsonData = jsonDecode(response.body);
      return ComplianceAudit.fromJson(jsonData);
    } catch (e) {
      throw Exception('Error generating compliance audit: $e');
    }
  }

  /// Retrieve a compliance audit by ID
  Future<ComplianceAudit> getComplianceAudit(String complianceId) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/compliance-audit/$complianceId'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to retrieve compliance audit: ${response.body}');
      }

      final jsonData = jsonDecode(response.body);
      return ComplianceAudit.fromJson(jsonData);
    } catch (e) {
      throw Exception('Error retrieving compliance audit: $e');
    }
  }

  /// Generate compliance audit PDF report
  Future<String> generateCompliancePdf(
    ComplianceAudit compliance, {
    String? clientName,
    String? companyName,
    String? companyDetails,
  }) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      // Build query parameters for optional company info
      final queryParams = <String, String>{};

      if (clientName != null) queryParams['client_name'] = clientName;
      if (companyName != null) queryParams['company_name'] = companyName;
      if (companyDetails != null) queryParams['company_details'] = companyDetails;

      // Use path parameter for compliance_id
      final uri = Uri.parse('$_apiUrl/api/compliance/generate-pdf/${compliance.id}')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('PDF generation failed: ${response.body}');
      }

      // Handle download based on platform
      if (kIsWeb) {
        // For web, use JavaScript to trigger browser download
        _triggerWebDownload(response.bodyBytes, 'compliance-report.pdf');
        return 'compliance-report.pdf (downloaded)';
      } else {
        // For mobile/desktop, save to local file system
        final directory = await getDownloadsDirectory();
        if (directory == null) throw Exception('Downloads directory not found');

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${directory.path}/compliance-report-$timestamp.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return filePath;
      }
    } catch (e) {
      throw Exception('Error generating PDF: $e');
    }
  }

  /// Delete a compliance audit
  Future<void> deleteComplianceAudit(String complianceId) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.delete(
        Uri.parse('$_apiUrl/api/compliance-audit/$complianceId'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete compliance audit: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting compliance audit: $e');
    }
  }

  /// Get compliance audit history (list of compliance audits)
  Future<List<ComplianceAudit>> getComplianceHistory({int limit = 100}) async {
    if (_authToken == null || _authToken!.isEmpty) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/api/compliance-audit/history/list?limit=$limit'),
        headers: _buildHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // If 404 or 401, treat as empty list (user may not have compliance audits)
        if (response.statusCode == 404 || response.statusCode == 401) {
          return [];
        }
        throw Exception('Failed to retrieve compliance history: ${response.body}');
      }

      final jsonData = jsonDecode(response.body) as List;
      return jsonData.map((item) => ComplianceAudit.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Error retrieving compliance history: $e');
    }
  }

  /// Trigger browser download for web platform using blob URLs
  void _triggerWebDownload(List<int> pdfBytes, String filename) {
    if (kIsWeb) {
      try {
        // Create a blob from the PDF bytes
        final blob = html.Blob([pdfBytes], 'application/pdf');

        // Create a blob URL (more reliable than data URLs)
        final blobUrl = html.Url.createObjectUrl(blob);

        // Use JavaScript to trigger download via blob URL
        _downloadViaJS(blobUrl, filename);

        // Clean up the blob URL after a delay
        Future.delayed(Duration(seconds: 2), () {
          try {
            html.Url.revokeObjectUrl(blobUrl);
          } catch (e) {
            print('Note: Could not revoke blob URL: $e');
          }
        });
      } catch (e) {
        print('Error preparing PDF blob download: $e');
      }
    }
  }

  /// Helper to trigger download via JavaScript using blob URL
  void _downloadViaJS(String blobUrl, String filename) {
    if (kIsWeb) {
      try {
        // Create an anchor element to trigger the download
        final anchor = html.AnchorElement()
          ..href = blobUrl
          ..download = filename
          ..style.display = 'none';

        // Append to document body
        html.window.document.documentElement?.append(anchor);

        // Trigger the download
        anchor.click();

        // Clean up - remove the anchor from DOM after a short delay
        Future.delayed(Duration(milliseconds: 200), () {
          try {
            anchor.remove();
          } catch (e) {
            print('Note: Could not remove download element: $e');
          }
        });

        print('PDF download triggered via blob: $filename');
      } catch (e) {
        print('Error triggering PDF blob download: $e');
      }
    }
  }
}
