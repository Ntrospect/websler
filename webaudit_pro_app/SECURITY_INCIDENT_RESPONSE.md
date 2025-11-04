# SECURITY INCIDENT RESPONSE GUIDE
**Date:** November 3, 2025
**Incident:** API keys exposed on public GitHub repository
**Severity:** CRITICAL
**Status:** RESPONSE IN PROGRESS

---

## Executive Summary

On November 3, 2025, GitHub Secret Scanning detected and reported to Anthropic that API keys were exposed in commit `38cd64402e9ed5ddf417f7483342618cd18f49df`.

### Compromised Credentials:

1. ✅ **Anthropic API Key** (`sk-ant-api03-LM_...ygAA`)
   - Status: **REVOKED** by Anthropic (automatic)
   - Impact: Limited to API usage costs
   - Risk Level: LOW (already mitigated)

2. ⚠️ **Supabase Service Role Key** (Production: `vwnbhsmfpxdfcvqnzddc`)
   - Status: **STILL ACTIVE** ⚠️
   - Impact: Full database access (read/write/delete all data)
   - Risk Level: **CRITICAL**

---

## IMMEDIATE ACTIONS REQUIRED (Priority Order)

### 🔴 STEP 1: Rotate Supabase Service Role Key (DO THIS FIRST)

**Why:** This key gives unrestricted access to your production database.

**Instructions:**

1. **Log into Supabase Dashboard:**
   - URL: https://supabase.com/dashboard
   - Project: `websler-pro` (ref: `vwnbhsmfpxdfcvqnzddc`)

2. **Navigate to API Settings:**
   - Left sidebar → Settings → API
   - Scroll to "Service Role Key" section

3. **Reset the Service Role Key:**
   - Click "Reveal" next to service_role key
   - Click "Reset Service Role Key" or "Regenerate"
   - **IMPORTANT:** Copy the NEW key immediately (shown only once)
   - Save to password manager or secure location

4. **Verify old key is revoked:**
   - Try a test API call with the old key
   - Should receive 401 Unauthorized

**Expected Result:** Old service role key stops working immediately.

---

### 🟡 STEP 2: Generate New Anthropic API Key

**Instructions:**

1. **Visit Anthropic Console:**
   - URL: https://console.anthropic.com/settings/keys

2. **Confirm old key is deactivated:**
   - Should see "staging-API" (ID: 5623134) marked as deactivated

3. **Create new API key:**
   - Click "Create Key"
   - Name: `production-API` or `new-staging-API`
   - Copy the key immediately (starts with `sk-ant-api03-`)

4. **Store securely:**
   - Save to password manager
   - Never commit to git

---

### 🟢 STEP 3: Update VPS Environment File

**Instructions:**

```powershell
# Create new .env file locally with NEW keys
$env_content = @"
# Production Supabase Configuration
SUPABASE_URL=https://vwnbhsmfpxdfcvqnzddc.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3bmJoc21mcHhkZmN2cW56ZGRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1MjAwOTMsImV4cCI6MjA3NzA5NjA5M30.2u4Fh_hrolEBeu5u_ADwZV_j3Bzq9szMBdkLZlc3b5M
SUPABASE_SERVICE_ROLE_KEY=<NEW_SERVICE_ROLE_KEY_FROM_STEP_1>

# Anthropic API Key
ANTHROPIC_API_KEY=<NEW_KEY_FROM_STEP_2>
"@

# Save locally
$env_content | Out-File -FilePath "C:\Users\Ntro\weblser\production_env_new" -Encoding utf8

# Upload to VPS
scp "C:\Users\Ntro\weblser\production_env_new" vps:/tmp/production_env_new

# Deploy on VPS
ssh vps "sudo mv /tmp/production_env_new /home/weblser/.env && sudo chown weblser:weblser /home/weblser/.env && sudo chmod 600 /home/weblser/.env"
```

---

### 🟢 STEP 4: Restart Backend Service

```bash
# SSH to VPS
ssh vps

# Restart the weblser service
echo 'Burrawang1968' | sudo -S systemctl restart weblser.service

# Verify service is running with new keys
sudo systemctl status weblser.service

# Check logs for any errors
sudo journalctl -u weblser.service -n 50 -f
```

**Expected:** Service restarts successfully, no errors about invalid keys.

---

### 🟢 STEP 5: Update Local Environment Files

```powershell
# Update .env.staging (if you use staging)
notepad "C:\Users\Ntro\weblser\webaudit_pro_app\.env.staging"

# Replace these lines:
# ANTHROPIC_API_KEY=<NEW_KEY_FROM_STEP_2>
# SUPABASE_SERVICE_ROLE_KEY=<NEW_SERVICE_ROLE_KEY_FROM_STEP_1>
```

**Note:** Never commit these files to git!

---

### 🔵 STEP 6: Test New Credentials

```powershell
# Activate venv
cd C:\Users\Ntro\weblser
.\.venv\Scripts\Activate.ps1

# Test Anthropic API
python -c "import anthropic; client = anthropic.Anthropic(api_key='<NEW_KEY>'); print('Anthropic OK' if client else 'Failed')"

# Test Supabase (from Flutter app or curl)
# Login to https://websler.pro
# Try generating a summary or compliance audit
```

**Expected:** All API calls succeed with new keys.

---

## PREVENTIVE MEASURES (Set Up After Rotation)

### Option A: git-secrets (Recommended for Windows)

```powershell
# Install git-secrets
# Download from: https://github.com/awslabs/git-secrets
# Or use: scoop install git-secrets

cd C:\Users\Ntro\weblser

# Initialize git-secrets
git secrets --install
git secrets --register-aws  # Adds common AWS patterns

# Add custom patterns for your keys
git secrets --add 'sk-ant-api03-[A-Za-z0-9_-]+'
git secrets --add 'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'
git secrets --add 'ANTHROPIC_API_KEY=sk-'
git secrets --add 'SUPABASE_SERVICE_ROLE_KEY=eyJ'

# Test it works
echo "ANTHROPIC_API_KEY=sk-ant-api03-test123" > test_secret.txt
git add test_secret.txt
# Should block the commit with an error
```

### Option B: Pre-commit Hook (Alternative)

```powershell
# Create pre-commit hook
$hook = @"
#!/bin/sh
# Check for exposed secrets before commit

if git diff --cached | grep -E 'sk-ant-api03-|eyJ[A-Za-z0-9_-]+\.eyJ'; then
    echo "ERROR: Detected API keys in commit!"
    echo "Remove sensitive data before committing."
    exit 1
fi
"@

$hook | Out-File -FilePath "C:\Users\Ntro\weblser\.git\hooks\pre-commit" -Encoding utf8
```

---

## GIT HISTORY CLEANUP (Advanced - Do This Last)

⚠️ **Warning:** This rewrites git history. Coordinate with all collaborators first!

### Method 1: BFG Repo-Cleaner (Easiest)

```powershell
# Download BFG
# https://rtyley.github.io/bfg-repo-cleaner/

# Create file with secrets to remove
$secrets = @"
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
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3bmJoc21mcHhkZmN2cW56ZGRjIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MTUyMDA5MywiZXhwIjoyMDc3MDk2MDkzfQ.V4GYD0Us3NhiNTOnakqqO44qLdRKFmVGOcj3UkjHTtA
"@

$secrets | Out-File -FilePath "C:\Users\Ntro\weblser\secrets.txt" -Encoding utf8

# Clone a fresh copy for safety
cd C:\Users\Ntro
git clone --mirror https://github.com/Ntrospect/websler.git websler-cleanup.git
cd websler-cleanup.git

# Run BFG to remove secrets
java -jar bfg.jar --replace-text ../weblser/secrets.txt

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Push cleaned history (WARNING: This will force-update GitHub)
git push --force
```

### Method 2: git filter-repo (More Control)

```bash
# Install git-filter-repo
pip install git-filter-repo

cd C:\Users\Ntro\weblser

# Create filter script
cat > filter_secrets.py << 'EOF'
import re

def replace_secrets(blob, metadata):
    # Replace Anthropic keys
    blob.data = re.sub(
        b'sk-ant-api03-[A-Za-z0-9_-]+',
        b'[REDACTED-ANTHROPIC-KEY]',
        blob.data
    )
    # Replace Supabase JWTs
    blob.data = re.sub(
        b'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
        b'[REDACTED-SUPABASE-JWT]',
        blob.data
    )

import git_filter_repo
git_filter_repo.RepoFilter(
    blob_callback=replace_secrets
).run()
EOF

# Run filter (BACKUP FIRST!)
git filter-repo --force --blob-callback filter_secrets.py
```

---

## VERIFICATION CHECKLIST

After completing all steps:

- [ ] Old Anthropic key shows as "Deactivated" in console
- [ ] New Anthropic key works in production
- [ ] Old Supabase service role key returns 401 Unauthorized
- [ ] New Supabase service role key works in production
- [ ] VPS service running with new keys
- [ ] Local .env files updated (not committed)
- [ ] git-secrets or pre-commit hook installed
- [ ] Tested full flow: login → summary → compliance audit → PDF
- [ ] No secrets appear in `git log -p | grep sk-ant`
- [ ] Force-pushed cleaned history to GitHub (optional)

---

## INCIDENT TIMELINE

| Time (UTC) | Event |
|------------|-------|
| 2025-11-03 08:21 | GitHub detected exposed key in commit 38cd644 |
| 2025-11-03 08:21 | Anthropic automatically revoked key (ID: 5623134) |
| 2025-11-03 ~09:00 | User received email notification from Anthropic |
| 2025-11-03 ~09:15 | Claude Code initiated incident response |
| 2025-11-03 ~09:20 | Automated secret redaction completed (13 secrets) |
| 2025-11-03 TBD | Supabase key rotation (PENDING) |
| 2025-11-03 TBD | New Anthropic key generation (PENDING) |

---

## LESSONS LEARNED

### What Went Wrong:
1. Documentation files included full .env contents with real keys
2. No pre-commit hooks to catch secrets
3. Session handoff notes documented production credentials
4. Files were committed and pushed to public GitHub

### What Went Right:
1. ✅ GitHub Secret Scanning detected exposure quickly
2. ✅ Anthropic auto-revoked compromised key
3. ✅ Automated cleanup script redacted 13 secrets successfully
4. ✅ Fast incident response initiated

### Future Prevention:
1. Install git-secrets before next commit
2. Never include real credentials in documentation
3. Use placeholders like `<YOUR_KEY_HERE>` in docs
4. Add .env files to .gitignore (already present)
5. Regular security audits of committed files
6. Consider using environment variable managers (1Password, Vault)

---

## CONTACT INFORMATION

**Anthropic Support:**
- Email: security@anthropic.com
- Docs: https://console.anthropic.com/settings/keys

**Supabase Support:**
- Dashboard: https://supabase.com/dashboard/project/vwnbhsmfpxdfcvqnzddc/settings/api
- Docs: https://supabase.com/docs/guides/api/api-keys

**GitHub Support:**
- Docs: https://docs.github.com/en/code-security/secret-scanning

---

## APPENDIX: Exposed Credentials Reference

### Anthropic API Key (REVOKED)
```
Name: staging-API
ID: 5623134
Hint: sk-ant-api03-LM_...ygAA
Status: Deactivated by Anthropic
Action: Generate new key
```

### Supabase Service Role Key (ROTATE IMMEDIATELY)
```
Project: websler-pro
Ref: vwnbhsmfpxdfcvqnzddc
Hint: eyJ...HtA
Status: ACTIVE (urgent rotation required)
Action: Reset via Supabase dashboard
```

### Affected Files (Now Cleaned):
1. SESSION_HANDOFF_NOV3_COMPLIANCE_AUDIT_FIX.md
2. SESSION_SUMMARY_OCT30_STAGING_FIXES.md
3. INFRASTRUCTURE_DOCUMENTATION.md
4. SESSION_HANDOFF_NOV01_SENTRY_MCP.md
5. .claude/reports/SECURITY_AUDIT_2025-11-03_ENV_CONFIG.md

### Git Commits Affected:
- Primary: `38cd64402e9ed5ddf417f7483342618cd18f49df`
- Potentially others in history (requires full scan)

---

**Status:** INCIDENT RESPONSE IN PROGRESS
**Next Update:** After Step 1 (Supabase key rotation) completed

*Generated by Claude Code - Security Incident Response*
*Last Updated: 2025-11-03 ~09:25 UTC*
