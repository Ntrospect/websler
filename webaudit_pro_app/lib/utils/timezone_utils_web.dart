// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;

/// Web-specific implementation using JavaScript Intl API
/// Detects the browser's IANA timezone identifier
String? getJsTimezone() {
  try {
    // Call JavaScript: Intl.DateTimeFormat().resolvedOptions().timeZone
    final intl = js.context['Intl'];
    if (intl == null) {
      print('⚠️ JavaScript Intl API not available');
      return null;
    }

    final dateTimeFormat = intl.callMethod('DateTimeFormat', []);
    final resolvedOptions = dateTimeFormat.callMethod('resolvedOptions', []);
    final timeZone = resolvedOptions['timeZone'] as String?;

    if (timeZone != null && timeZone.isNotEmpty) {
      print('✅ Detected browser timezone from Intl API: $timeZone');
      return timeZone;
    } else {
      print('⚠️ Browser timezone detection returned empty');
      return null;
    }
  } catch (e) {
    print('❌ Error detecting browser timezone: $e');
    return null;
  }
}
