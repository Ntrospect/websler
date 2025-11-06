import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
// Conditional import for web-only JavaScript interop
import 'timezone_utils_stub.dart'
    if (dart.library.js) 'timezone_utils_web.dart' as tz_impl;

/// Timezone utilities for user-specific timestamp formatting
class TimezoneUtils {
  /// Common timezones for user selection (Option A)
  static const Map<String, String> commonTimezones = {
    'UTC': 'UTC (Coordinated Universal Time)',
    'America/New_York': 'Eastern Time (US & Canada)',
    'America/Chicago': 'Central Time (US & Canada)',
    'America/Denver': 'Mountain Time (US & Canada)',
    'America/Los_Angeles': 'Pacific Time (US & Canada)',
    'Europe/London': 'London (GMT/BST)',
    'Europe/Paris': 'Paris (CET/CEST)',
    'Asia/Tokyo': 'Tokyo (JST)',
    'Australia/Sydney': 'Sydney (AEDT/AEST)',
  };

  /// Get list of timezone identifiers
  static List<String> get timezoneIds => commonTimezones.keys.toList();

  /// Get display name for timezone
  static String getDisplayName(String timezoneId) {
    return commonTimezones[timezoneId] ?? timezoneId;
  }

  /// Auto-detect user's browser timezone
  /// Returns IANA timezone identifier (e.g., 'America/New_York')
  static String detectBrowserTimezone() {
    try {
      // For web platform only - uses dart:html and js interop
      // For mobile/desktop, this will return UTC
      if (kIsWeb) {
        try {
          // Use JavaScript Intl API to get IANA timezone
          // This is the most reliable way to detect timezone on web
          final jsResult = _getJsTimezone();

          // Validate that the detected timezone is in our common list
          // If not, return UTC as a safe fallback
          if (jsResult != null && commonTimezones.containsKey(jsResult)) {
            print('✅ Auto-detected browser timezone: $jsResult');
            return jsResult;
          } else {
            print('⚠️ Detected timezone not in common list: $jsResult, using UTC');
            return 'UTC';
          }
        } catch (e) {
          print('⚠️ Browser timezone detection failed: $e');
          return 'UTC';
        }
      } else {
        // For mobile/desktop platforms, default to UTC
        // Users can manually select their timezone in Settings
        return 'UTC';
      }
    } catch (e) {
      print('Error detecting timezone: $e');
      return 'UTC'; // Safe fallback
    }
  }

  /// Get timezone from JavaScript Intl API (web only)
  static String? _getJsTimezone() {
    return tz_impl.getJsTimezone();
  }

  /// Format ISO timestamp to user's local timezone
  /// Input: ISO 8601 UTC timestamp (e.g., '2025-11-06T12:30:00Z')
  /// Output: Formatted local time (e.g., 'Nov 6, 2025 at 7:30 AM EST')
  static String formatToUserTimezone(String isoTimestamp, String userTimezone) {
    try {
      // Parse ISO timestamp
      final utcTime = DateTime.parse(isoTimestamp);

      // Convert to user's timezone
      // Note: For now we'll use DateTime's built-in local conversion
      // For production, consider using timezone package for proper IANA support
      final localTime = utcTime.toLocal();

      // Format: "Nov 6, 2025 at 7:30 AM"
      final formatter = DateFormat('MMM d, yyyy \'at\' h:mm a');
      final formatted = formatter.format(localTime);

      // Add timezone abbreviation
      final tzAbbr = _getTimezoneAbbreviation(userTimezone, localTime);
      return '$formatted $tzAbbr';
    } catch (e) {
      print('Error formatting timestamp: $e');
      return isoTimestamp; // Fallback to raw timestamp
    }
  }

  /// Get timezone abbreviation (EST, PST, etc.)
  static String _getTimezoneAbbreviation(String timezoneId, DateTime dateTime) {
    // Simplified mapping - in production, use timezone package
    final abbreviations = {
      'America/New_York': _isDST(dateTime) ? 'EDT' : 'EST',
      'America/Chicago': _isDST(dateTime) ? 'CDT' : 'CST',
      'America/Denver': _isDST(dateTime) ? 'MDT' : 'MST',
      'America/Los_Angeles': _isDST(dateTime) ? 'PDT' : 'PST',
      'Europe/London': _isDST(dateTime) ? 'BST' : 'GMT',
      'Europe/Paris': _isDST(dateTime) ? 'CEST' : 'CET',
      'Asia/Tokyo': 'JST',
      'Australia/Sydney': _isDST(dateTime) ? 'AEDT' : 'AEST',
      'UTC': 'UTC',
    };

    return abbreviations[timezoneId] ?? 'UTC';
  }

  /// Simple DST detection (March-November in Northern Hemisphere)
  /// Note: This is simplified - production should use timezone package
  static bool _isDST(DateTime dateTime) {
    final month = dateTime.month;
    // DST typically March-November in Northern Hemisphere
    return month >= 3 && month <= 11;
  }

  /// Format relative time (e.g., "2 hours ago", "yesterday")
  static String formatRelativeTime(String isoTimestamp) {
    try {
      final timestamp = DateTime.parse(isoTimestamp);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        final mins = difference.inMinutes;
        return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      } else {
        // For older items, show formatted date
        final formatter = DateFormat('MMM d, yyyy');
        return formatter.format(timestamp.toLocal());
      }
    } catch (e) {
      print('Error formatting relative time: $e');
      return isoTimestamp;
    }
  }
}
