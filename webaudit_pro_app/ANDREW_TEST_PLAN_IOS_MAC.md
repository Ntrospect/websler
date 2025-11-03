# Websler Pro Testing Guide for Andrew (iOS/macOS)

**Test Date:** November 3, 2025
**Version:** 1.2.2
**Environment:** Production (https://websler.pro)
**Tester:** Andrew (iOS/Mac devices only)

---

## Overview

Hi Andrew! 👋

Welcome to the Websler Pro testing guide. This document will walk you through testing our website analysis tool on your Apple devices. The app works in Safari on both Mac and iOS (iPhone/iPad) - no app download needed!

**What you're testing:** A web app that analyzes websites for SEO, accessibility, compliance, and more.

**Estimated time:** 30-45 minutes
**Prerequisites:** None - just your Apple device and an internet connection!

---

## Device Information

Before you start, please note which devices you're testing on:

- [ ] **Mac** (Safari browser)
  - macOS version: _____________
  - Screen size: _____________

- [ ] **iPhone** (Safari browser)
  - iOS version: _____________
  - Model: _____________

- [ ] **iPad** (Safari browser)
  - iOS version: _____________
  - Model: _____________

---

## Test Environment Setup

### Step 1: Open Safari
1. Open Safari browser on your device
2. Navigate to: **https://websler.pro**
3. The page should load without any security warnings
4. You should see a clean, professional login screen

**✅ Expected Result:** Website loads securely with HTTPS lock icon in address bar

**❌ Report if:** You see any security warnings, certificate errors, or the page doesn't load

---

## Test Section 1: Account Creation & Login

### Test 1.1: Sign Up (New Account)

**Steps:**
1. On the login screen, click **"Sign Up"** (or similar button)
2. Fill in the signup form:
   - **Full Name:** Andrew [Your Last Name]
   - **Email:** Use your email address
   - **Password:** Create a strong password (at least 8 characters)
   - **Confirm Password:** Re-enter your password
3. Accept terms & conditions (if checkbox present)
4. Click **"Sign Up"** or **"Create Account"**
5. Wait for account creation (should take 2-5 seconds)

**✅ Expected Result:**
- Account creates successfully
- You're automatically logged in
- You see the Home screen with "Analyze Your Website" card

**❌ Report if:**
- Signup button doesn't work
- You get an error message
- Password requirements aren't clear
- Account creates but you're not logged in

**iOS/Safari Specific:**
- [ ] Safari autofill offers to save your password
- [ ] All form fields are tappable and keyboard appears correctly
- [ ] No layout issues with on-screen keyboard

---

### Test 1.2: Logout & Login

**Steps:**
1. Click your profile icon or settings (top-right corner)
2. Click **"Logout"** or **"Sign Out"**
3. Confirm logout (if prompted)
4. You should be back at the login screen
5. Enter your email and password
6. Click **"Login"** or **"Sign In"**

**✅ Expected Result:**
- Logout is instant
- Login works with correct credentials
- You return to the Home screen after login

**❌ Report if:**
- Logout button doesn't work
- Login fails with correct credentials
- Session doesn't persist (you're logged out unexpectedly)

**iOS/Safari Specific:**
- [ ] Safari remembers your login credentials
- [ ] Face ID/Touch ID prompts (if you have it enabled for Safari)

---

## Test Section 2: Website Analysis Features

### Test 2.1: Generate Website Summary (Websler)

**Steps:**
1. On the **Home** screen, find the "Analyze Your Website" card
2. In the URL input field, enter: **https://apple.com**
3. Click **"Generate Summary"** button
4. Wait for analysis (should take 10-30 seconds)
5. A dialog should appear with the summary

**✅ Expected Result:**
- Loading spinner appears during analysis
- Summary dialog appears with:
  - Website URL
  - Website title
  - AI-generated summary (2-3 sentences)
  - "Close" and "Upgrade to Pro Audit" buttons

**❌ Report if:**
- Analysis takes longer than 60 seconds
- Error message appears
- Summary is empty or nonsensical
- Dialog doesn't appear

**iOS/Safari Specific:**
- [ ] Keyboard dismisses when you submit
- [ ] Dialog scrolls properly if summary is long
- [ ] Buttons are tappable (not too small)

---

### Test 2.2: Upgrade to Full Audit

**Steps:**
1. After generating a summary, click **"Upgrade to Pro Audit"**
2. Wait for full audit (this takes **2-5 minutes** - grab a coffee! ☕)
3. You'll see a loading dialog: "Running WebAudit Pro... This may take 1 to 3 minutes"
4. When complete, you should see a success message
5. Go to the **History** tab

**✅ Expected Result:**
- Loading dialog appears and stays visible during audit
- Success message: "✓ Audit complete! Check the History tab."
- Audit appears in History tab with:
  - Website URL
  - Date/time
  - Overall score (color-coded)
  - "View Audit" button

**❌ Report if:**
- Audit times out or fails
- Loading dialog disappears prematurely
- Audit doesn't appear in history
- Any error messages

**iOS/Safari Specific:**
- [ ] Screen doesn't auto-lock during long audit (stay on the page)
- [ ] Dialog remains visible and doesn't get dismissed accidentally
- [ ] No mobile Safari refresh issues

---

### Test 2.3: View Audit Results

**Steps:**
1. In the **History** tab, find your audit
2. Click **"View Audit"** button
3. Scroll through the 10-point evaluation
4. Expand individual sections (SEO, Performance, Accessibility, etc.)
5. Read the recommendations

**✅ Expected Result:**
- Audit results screen loads
- Overall score is prominently displayed (large number with color)
- 10 evaluation categories are listed
- Each category shows:
  - Score (0-100)
  - Status (Pass/Warning/Fail)
  - Recommendations when expanded
- Websler Pro logo visible in top-right corner

**❌ Report if:**
- Scores don't load
- Sections don't expand/collapse
- Text is unreadable or overlapping
- Layout is broken

**iOS/Safari Specific:**
- [ ] Page scrolls smoothly
- [ ] Expansion animations work properly
- [ ] Text is readable at normal zoom level
- [ ] No horizontal scrolling required

---

### Test 2.4: Compliance Audit (Optional Advanced Test)

**Steps:**
1. From the **History** tab, find an audit
2. Click **"Upgrade to Compliance Audit"**
3. Select jurisdictions (Australia and New Zealand are pre-selected)
4. You can toggle GDPR (EU) and CCPA (California) if you want
5. Click **"Run Compliance Audit"** button
6. Wait 2-5 minutes for compliance analysis
7. View results when complete

**✅ Expected Result:**
- Jurisdiction selection screen appears with flags
- Checkboxes work for toggling jurisdictions
- Compliance audit completes (2-5 minutes)
- Results show compliance status for each jurisdiction
- Specific recommendations per jurisdiction

**❌ Report if:**
- Jurisdiction selection doesn't work
- Audit fails or times out
- Results don't match selected jurisdictions
- Layout issues on mobile

**iOS/Safari Specific:**
- [ ] Checkboxes are tappable (large enough touch target)
- [ ] Flags display correctly (emoji rendering)
- [ ] Long jurisdiction names don't overflow

---

## Test Section 3: History & PDF Downloads

### Test 3.1: View History

**Steps:**
1. Click the **History** tab
2. You should see all your analyses listed
3. Analyses include summaries and audits
4. Each item shows:
   - Website URL
   - Date/time
   - Type (summary vs audit)
   - Overall score (for audits)
   - Action buttons

**✅ Expected Result:**
- History loads without errors
- Items are sorted by date (newest first)
- Summaries show blue badge
- Audits show color-coded score badges
- Pull-to-refresh works on mobile

**❌ Report if:**
- History is empty when you have analyses
- Items don't load
- Incorrect information displayed
- Can't distinguish summaries from audits

**iOS/Safari Specific:**
- [ ] Pull-to-refresh gesture works (swipe down on iOS)
- [ ] List scrolls smoothly
- [ ] No bouncing/layout issues

---

### Test 3.2: Download PDF Report

**Steps:**
1. In **History**, find an audit (not a summary)
2. Click **"View Audit"** to open the audit
3. Look for a **"Download PDF"** or **"Export PDF"** button
4. Click the button
5. Wait for PDF generation (5-10 seconds)
6. PDF should download to your device

**✅ Expected Result:**
- PDF downloads successfully
- File name: `websler-analysis-[timestamp].pdf`
- PDF opens in default viewer
- PDF contains:
  - Websler Pro logo (top-left)
  - Jumoki logo (top-right)
  - Website title and URL
  - Overall score
  - 10-point evaluation details
  - Recommendations

**❌ Report if:**
- PDF doesn't download
- Download hangs or fails
- PDF is corrupted or won't open
- PDF is missing content
- Logos are missing or broken

**iOS/Safari Specific:**
- [ ] **Mac:** PDF downloads to Downloads folder
- [ ] **iPhone/iPad:** PDF opens in Safari or prompts to open in Files app
- [ ] PDF is readable and properly formatted
- [ ] Can share PDF via iOS share sheet

---

## Test Section 4: Settings & Theme

### Test 4.1: Dark Mode Toggle

**Steps:**
1. Click the **Settings** tab (or gear icon)
2. Find the **"Dark Mode"** toggle
3. Turn Dark Mode **ON**
4. Check all screens (Home, History, Settings)
5. Turn Dark Mode **OFF**
6. Check screens again

**✅ Expected Result:**
- Toggle switches instantly
- All screens adapt to dark/light theme
- Text remains readable in both modes
- Logos change to match theme
- Theme persists after page reload

**❌ Report if:**
- Toggle doesn't work
- Some screens don't update
- Text is unreadable (poor contrast)
- Theme resets to light mode on refresh

**iOS/Safari Specific:**
- [ ] Theme matches iOS system appearance (if supported)
- [ ] No flashing/flickering during theme change
- [ ] Status bar color adapts (iOS)

---

### Test 4.2: View App Version

**Steps:**
1. In **Settings**, scroll down
2. Find the **"App Version"** section
3. Note the version number

**✅ Expected Result:**
- Version shows: **1.2.2**
- Version is clearly visible

**❌ Report if:**
- Version number is missing
- Shows incorrect version
- Section is hard to find

---

## Test Section 5: Responsive Design

### Test 5.1: Portrait vs Landscape (iPhone/iPad only)

**Steps:**
1. Open **Home** screen in portrait mode
2. Rotate device to landscape
3. Check layout adapts properly
4. Repeat for **History** and **Settings** tabs
5. Check **Audit Results** screen in both orientations

**✅ Expected Result:**
- Layout adapts smoothly to orientation
- No content is cut off
- Text remains readable
- Buttons are accessible
- No horizontal scrolling

**❌ Report if:**
- Layout breaks in landscape
- Content overlaps
- Buttons are unreachable
- Excessive white space

---

### Test 5.2: Safari Split View (iPad only)

**Steps:**
1. Open websler.pro in Safari
2. Enable Split View with another app
3. Resize the Safari window
4. Check all screens adapt properly

**✅ Expected Result:**
- App adapts to smaller width
- Layout switches to mobile view when narrow
- All features remain accessible

**❌ Report if:**
- Layout breaks in Split View
- Content becomes inaccessible
- App doesn't resize properly

---

## Test Section 6: Edge Cases & Error Handling

### Test 6.1: Invalid URL Input

**Steps:**
1. On **Home** screen, try entering invalid URLs:
   - `not a url`
   - `google com` (no protocol)
   - `https://` (incomplete)
   - `https://fake site with spaces.com`
2. Click "Generate Summary" for each

**✅ Expected Result:**
- Error message appears for invalid URLs
- Error message is helpful and clear
- App doesn't crash
- Can correct the URL and retry

**❌ Report if:**
- No error message
- Cryptic error message
- App crashes or freezes
- Can't recover from error

---

### Test 6.2: Network Interruption

**Steps:**
1. Start generating a summary
2. While analysis is running, enable Airplane Mode
3. Wait to see what happens
4. Re-enable internet
5. Check if analysis recovers or provides error

**✅ Expected Result:**
- Error message indicates network problem
- App doesn't crash
- Can retry analysis after reconnecting

**❌ Report if:**
- App hangs indefinitely
- No error message
- App crashes
- Can't retry after reconnection

---

### Test 6.3: Logout While Analysis Running

**Steps:**
1. Start a full audit (2-5 minute operation)
2. While it's running, logout
3. Login again
4. Check **History** tab

**✅ Expected Result:**
- Audit completes even after logout
- Audit appears in history after re-login
- No data loss

**❌ Report if:**
- Audit is lost after logout
- App crashes
- Audit doesn't appear in history

---

## Test Section 7: Performance & Speed

### Test 7.1: Page Load Times

**Test each screen and note load time:**

- [ ] Login screen: _____ seconds
- [ ] Home screen: _____ seconds
- [ ] History screen: _____ seconds
- [ ] Settings screen: _____ seconds
- [ ] Audit Results screen: _____ seconds

**✅ Acceptable:** All screens load within 2 seconds

**❌ Report if:** Any screen takes longer than 5 seconds to load

---

### Test 7.2: Animation Smoothness

**Rate the smoothness of these animations (1-5, where 5 is perfectly smooth):**

- [ ] Theme switching: _____/5
- [ ] Tab navigation: _____/5
- [ ] Expanding audit sections: _____/5
- [ ] Dialog appearances: _____/5
- [ ] Pull-to-refresh: _____/5

**✅ Acceptable:** All animations rate 4/5 or higher

**❌ Report if:** Any animation is choppy, laggy, or janky

---

## Test Section 8: iOS Safari Specific Features

### Test 8.1: Add to Home Screen (iOS only)

**Steps:**
1. Open websler.pro in Safari (iOS)
2. Tap the Share button (box with arrow)
3. Scroll down and tap **"Add to Home Screen"**
4. Confirm addition
5. Go to home screen and tap the Websler Pro icon
6. App should open full-screen

**✅ Expected Result:**
- Icon appears on home screen
- Icon has correct branding (Jumoki robot)
- App opens full-screen (no Safari UI)
- Functions normally

**❌ Report if:**
- Can't add to home screen
- Icon is incorrect or default
- App doesn't open
- Features don't work in standalone mode

---

### Test 8.2: Safari AutoFill

**Steps:**
1. Logout of the app
2. Return to login screen
3. Check if Safari offers to autofill credentials
4. Use autofill to login

**✅ Expected Result:**
- Safari suggests saved password
- Autofill works correctly
- Login succeeds

**❌ Report if:**
- AutoFill doesn't work
- Wrong credentials offered
- Login fails with autofilled credentials

---

### Test 8.3: Safari Reader Mode

**Steps:**
1. Open an **Audit Results** page
2. Tap the Safari address bar
3. Look for Reader Mode icon (if available)
4. Try enabling it

**✅ Expected Result:**
- Reader Mode is not available (expected for web apps)
- If available, app still functions

**❌ Report if:**
- Reader Mode breaks the app
- Content becomes unreadable

---

## Bug Report Template

If you encounter any issues, please provide this information:

### Device & Environment
- **Device:** (Mac/iPhone/iPad + model)
- **OS Version:** (macOS 15.0 / iOS 18.0 / etc.)
- **Safari Version:** (Settings > Safari > About)
- **Screen Size/Orientation:** (if relevant)

### Issue Description
- **What happened?**
- **What did you expect to happen?**
- **Steps to reproduce:**
  1.
  2.
  3.

### Screenshots
- Please attach screenshots if possible
- Use iPhone/iPad screenshot (Power + Volume Up)
- Use Mac screenshot (Cmd + Shift + 4)

### Severity
- [ ] **Critical** - Can't use the app
- [ ] **High** - Major feature doesn't work
- [ ] **Medium** - Minor feature issue
- [ ] **Low** - Cosmetic or UI polish

---

## Summary Checklist

After completing all tests, please check off:

### Core Functionality
- [ ] Account creation works
- [ ] Login/logout works
- [ ] Website summary generation works
- [ ] Full audit generation works
- [ ] Compliance audit works
- [ ] History displays correctly
- [ ] PDF downloads work

### User Experience
- [ ] All buttons are tappable
- [ ] Text is readable (not too small)
- [ ] No layout issues
- [ ] Dark mode works
- [ ] Theme persists
- [ ] Animations are smooth

### iOS/Safari Specific
- [ ] Tested on Mac (Safari)
- [ ] Tested on iPhone (Safari)
- [ ] Tested on iPad (Safari)
- [ ] Portrait/landscape rotation works
- [ ] Add to Home Screen works
- [ ] AutoFill works

### Overall Impression
- **Would you use this app?** Yes / No / Maybe
- **What did you like most?**
- **What frustrated you?**
- **Any suggestions for improvement?**

---

## Contact

If you have questions during testing, contact:

- **Dean:** [Your contact info]
- **Email:** dean@jumoki.agency

---

**Thank you for testing Websler Pro, Andrew!** 🎉

Your feedback is invaluable in making this product better for all users.

---

*Test Plan Created: November 3, 2025*
*Version: 1.2.2*
*Target URL: https://websler.pro*
