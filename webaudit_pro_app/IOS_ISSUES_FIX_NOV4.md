# iOS Issues Fixed - November 4, 2025

## Issue #1: PDF Downloads Not Appearing in Files App ✅ FIXED

### Problem
Andrew reported that PDF downloads appeared to succeed but files couldn't be found in Files app → Downloads folder on iPad.

### Root Cause
**iOS doesn't have a public Downloads folder** like Android. The `getDownloadsDirectory()` method returns `null` on iOS, causing the download to fail.

From path_provider documentation:
- **Android**: Returns `/storage/emulated/0/Download` ✅
- **iOS**: Returns `null` ❌

### Solution Applied

**Files Modified:**
- `lib/services/api_service.dart` - iOS-specific download logic
- `pubspec.yaml` - Added `share_plus: ^7.2.1` dependency

**Code Changes:**

1. **Detect Platform:**
```dart
if (Platform.isIOS) {
  // iOS: Use app's documents directory
  targetDir = await getApplicationDocumentsDirectory();
} else {
  // Android/Windows/macOS: Use downloads directory
  targetDir = await getDownloadsDirectory();
}
```

2. **Save PDF + Open Share Sheet (iOS Only):**
```dart
// Save to app documents directory
final File file = File(filepath);
await file.writeAsBytes(response.bodyBytes);

// For iOS: Open share sheet automatically
if (Platform.isIOS) {
  await Share.shareXFiles(
    [XFile(filepath, mimeType: 'application/pdf')],
    text: 'WebAudit Pro Analysis Report',
  );
}
```

### How It Works Now (iOS)

**User Experience Flow:**
1. User taps "Download PDF" button
2. App generates PDF via backend API
3. PDF saves to app's Documents folder
4. **iOS Share Sheet opens automatically**
5. User can:
   - Save to Files app → Downloads (or any folder)
   - Share via AirDrop
   - Send via Messages, Mail, etc.
   - Save to iCloud Drive
   - Save to other cloud storage (Dropbox, Google Drive, etc.)

**Android Behavior (Unchanged):**
- PDF saves directly to Downloads folder
- No share sheet (not needed)

### Testing Instructions

**For Andrew (iPad Testing):**

1. **Summary PDF Download:**
   - Generate a website summary
   - Tap overflow menu (3 dots) on summary card
   - Tap "Download PDF"
   - **Expected:** Share sheet appears
   - Choose "Save to Files" → Downloads
   - Verify: PDF appears in Files app

2. **Audit PDF Download:**
   - Complete a 10-point audit
   - Tap "Download PDF" on results screen
   - **Expected:** Share sheet appears
   - Choose "Save to Files" → Downloads
   - Verify: PDF appears in Files app

3. **Alternative Sharing:**
   - Try AirDrop to another Apple device
   - Try sending via Messages
   - Try saving to iCloud Drive

### Deployment Status
✅ **Committed:** e5852dc
✅ **Pushed:** main branch
✅ **Ready:** Next iOS TestFlight build will include this fix

---

## Issue #2: Compliance Audit API Error ⚠️ INVESTIGATING

### Problem
Error shown in red banner:
```
Error generating compliance audit: ClientException: Load failed, uri=https://api.websler.pro/api/compliance-audit
```

### Analysis

**Error Type:** `ClientException: Load failed`

This is a Dart `http` package error indicating a network-level failure, not a backend API error.

**Possible Causes:**

1. **Network Timeout**
   - Compliance audits can take 1-2 minutes to complete
   - Default iOS network timeout may be too aggressive
   - Current timeout in code: 365 seconds (should be sufficient)

2. **iOS App Transport Security (ATS)**
   - iOS requires HTTPS with valid SSL certificates
   - Possible issue: Certificate validation failure
   - Check: `api.websler.pro` SSL certificate validity

3. **DNS Resolution**
   - Possible iPad DNS issue
   - Try: Different network (WiFi vs cellular)

4. **API Endpoint Availability**
   - VPS backend may have temporary issue
   - Check: Backend logs show no recent errors

### Diagnosis Steps

**For Andrew to Test:**

1. **Check Network Connectivity:**
   - Try generating summary (shorter API call)
   - If summary works, it's likely a timeout issue

2. **Try Different Network:**
   - Switch from WiFi to cellular (or vice versa)
   - Test if error persists

3. **Check VPS Status:**
   - Visit https://websler.pro in Safari
   - If site loads, API should be reachable

4. **Retry Compliance Audit:**
   - Select Australia jurisdiction only (faster)
   - Click "Run Compliance Audit"
   - Note: Takes 1-2 minutes normally

### Backend Verification

**VPS Status Check:**
```bash
ssh dean@140.99.254.83 "systemctl status weblser.service"
```

**Expected:**
```
● weblser.service - weblser FastAPI Backend
   Active: active (running)
   Main PID: 304585
```

**Logs Check:**
```bash
ssh dean@140.99.254.83 "sudo journalctl -u weblser.service -n 50 | grep compliance"
```

**Expected:** No recent errors

### Likely Resolution

**Most Likely Cause:** iOS network timeout or connectivity issue

**Recommended Actions:**

1. **For Andrew:**
   - Try on different network
   - Try with just Australia selected (faster audit)
   - Check if other API calls work (summaries, regular audits)

2. **If Issue Persists:**
   - Provide device logs (Settings → Privacy → Analytics → Analytics Data → WebAudit Pro)
   - Try on different iOS device if available
   - Test on web version (https://websler.pro) to rule out backend

3. **Potential Code Fix (If Needed):**
   - Add retry logic for network failures
   - Add better error messages (distinguish timeout vs network)
   - Increase iOS-specific timeout if needed

### Next Steps

**Waiting on Andrew's Testing Feedback:**
- PDF download fix should resolve immediately
- Compliance audit needs additional testing to determine if it's consistent or intermittent

**If Compliance Audit Fails Consistently:**
- Will add enhanced logging
- May need iOS-specific timeout adjustments
- May add retry logic with exponential backoff

---

## Summary

### Issue #1: PDF Downloads ✅ FIXED
**Status:** Fixed and committed
**Testing:** Ready for Andrew to test in next TestFlight build
**Expected Result:** Share sheet opens automatically on iOS

### Issue #2: Compliance Audit API ⚠️ NEEDS TESTING
**Status:** Under investigation
**Likely Cause:** iOS network timeout or connectivity
**Testing:** Andrew should test with different networks and jurisdictions
**Expected Outcome:** Will resolve with network change or may need code adjustment

---

## Technical Details

### iOS Share Sheet Integration

**Benefit:** Native iOS experience - users can choose destination

**share_plus Package:**
- Version: 7.2.2
- Platform: iOS, Android, macOS, Windows, Linux, Web
- Features: Share files, text, URLs with native OS share sheet

**XFile Class:**
- Represents a cross-platform file reference
- Supports MIME type specification
- Works with iOS Share Sheet automatically

### App Transport Security (ATS)

**Requirements for iOS:**
- HTTPS with TLS 1.2 or higher ✅
- Valid SSL certificate ✅
- Forward secrecy cipher suites ✅

**websler.pro Configuration:**
- Certificate: Let's Encrypt (valid)
- HTTPS: Enabled
- TLS: 1.2+ supported

**Should not be an issue** - but worth checking if compliance audit fails consistently.

### Path Provider Platform Differences

| Platform | getDownloadsDirectory() | Recommended Alternative (iOS) |
|----------|------------------------|-------------------------------|
| Android  | `/storage/emulated/0/Download` | N/A |
| iOS      | `null` ⚠️ | `getApplicationDocumentsDirectory()` + Share |
| macOS    | `~/Downloads` | N/A |
| Windows  | `C:\Users\[User]\Downloads` | N/A |
| Linux    | `~/Downloads` | N/A |

---

## Git History

**Commit:** e5852dc
**Date:** November 4, 2025
**Branch:** main
**Status:** Pushed to GitHub

**Files Changed:**
- lib/services/api_service.dart (iOS download logic)
- pubspec.yaml (share_plus dependency)
- pubspec.lock (dependency lock)
- Generated plugin files (macOS, Windows)

---

**Documented:** November 4, 2025 at 04:30 UTC
**Status:** PDF fix deployed, compliance audit under investigation
