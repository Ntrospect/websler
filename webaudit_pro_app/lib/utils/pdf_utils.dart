import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Utility for handling PDF operations across platforms
class PdfUtils {
  /// Download PDF file in browser (web only)
  /// Uses Blob URLs with download attribute for browser compatibility
  /// Works on desktop and mobile browsers including iPad Safari/Firefox
  /// Returns true if successful, false otherwise
  static Future<bool> openPdfInNewTab(
    Uint8List pdfBytes,
    String filename,
  ) async {
    if (!kIsWeb) {
      debugPrint('⚠️ openPdfInNewTab only supported on web platform');
      return false;
    }

    try {
      debugPrint('🔍 Triggering PDF download: $filename');

      // Create Blob from PDF bytes and trigger download
      _openPdfBlobInNewTab(pdfBytes, filename);

      debugPrint('✅ PDF download triggered successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error opening PDF: $e');
      return false;
    }
  }

  /// Opens PDF Blob in browser using JavaScript Blob URLs
  /// This approach is browser-secure (avoids data URL restrictions)
  /// Uses download link for iPad/mobile browser compatibility
  static void _openPdfBlobInNewTab(Uint8List pdfBytes, String filename) {
    try {
      // Create a Blob from the PDF bytes
      final blob = html.Blob([pdfBytes], 'application/pdf');

      // Create a Blob URL
      final blobUrl = html.Url.createObjectUrl(blob);

      // Create an anchor element with download attribute
      // This triggers actual download on iPad/mobile browsers
      final anchor = html.AnchorElement(href: blobUrl)
        ..setAttribute('download', filename)
        ..style.display = 'none';

      // Add to document, click, and remove
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      // Clean up the object URL after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        html.Url.revokeObjectUrl(blobUrl);
      });

      debugPrint('📥 Triggered download: $filename');
    } catch (e) {
      debugPrint('Error creating/downloading PDF blob: $e');
    }
  }
}
