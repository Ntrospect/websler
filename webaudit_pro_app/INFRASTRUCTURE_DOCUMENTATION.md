# WebAudit Pro - Infrastructure Documentation

**Last Updated:** October 30, 2025
**Status:** Production Ready

---

## Table of Contents

1. [Supabase Configuration](#supabase-configuration)
2. [API Setup (FastAPI Backend)](#api-setup-fastapi-backend)
3. [SSL/HTTPS Configuration](#ssltls-configuration)
4. [Flutter Web Deployment](#flutter-web-deployment)
5. [DNS & Domain Configuration](#dns--domain-configuration)
6. [Environment Configuration](#environment-configuration)
7. [Health Checks & Monitoring](#health-checks--monitoring)
8. [Emergency Procedures](#emergency-procedures)
9. [Maintenance Schedule](#maintenance-schedule)

---

## Supabase Configuration

### Overview
Two separate Supabase projects for staging and production environments.

### Production Project (websler-pro)

| Property | Value |
|----------|-------|
| **Project ID** | `vwnbhsmfpxdfcvqnzddc` |
| **Project URL** | `https://vwnbhsmfpxdfcvqnzddc.supabase.co` |
| **Region** | `us-east-1` (Virginia) |
| **Database Version** | PostgreSQL 17.6.1.025 |
| **Status** | ACTIVE_HEALTHY |
| **Created** | October 24, 2025 |

#### Production API Keys

**Anon Key** (Public - Safe for frontend):
```
[REDACTED-SUPABASE-JWT]
```
**Location in Code:** `lib/config/environment.dart` (hardcoded for release builds)

**Service Role Key** (Private - Backend only):
```
[REDACTED-SUPABASE-JWT]
```
**Location:** `.env` file (not committed to git)

---

### Staging Project (websler-pro-staging)

| Property | Value |
|----------|-------|
| **Project ID** | `kmlhslmkdnjakkpluwup` |
| **Project URL** | `https://kmlhslmkdnjakkpluwup.supabase.co` |
| **Region** | `us-east-1` (Virginia) |
| **Database Version** | PostgreSQL 17.6.1.029 |
| **Status** | ACTIVE_HEALTHY |
| **Created** | October 29, 2025 |

#### Staging API Keys

**Anon Key** (Public - Safe for frontend):
```
[REDACTED-SUPABASE-JWT]
```
**Location in Code:** `lib/config/environment.dart` (hardcoded for debug builds)

---

### Database Schema (Both Projects)

#### Tables

| Table | Purpose | Key Columns | RLS Enabled |
|-------|---------|-----------|-----------|
| `auth.users` | Supabase authentication | id, email, email_confirmed_at | Yes |
| `public.users` | User profiles | id, email, full_name, avatar_url, company_name, company_details | Yes |
| `public.audit_results` | Audit findings | id, user_id, website_url, overall_score, audit_data (JSONB) | Yes |
| `public.website_summaries` | Quick summaries | id, user_id, website_url, summary, extracted_content | Yes |
| `public.recommendations` | Audit recommendations | id, user_id, audit_result_id, category, recommendation (JSONB) | Yes |
| `public.pdf_generations` | PDF download tracking | id, user_id, analysis_id, file_name, generated_at | Yes |

#### Row-Level Security (RLS)

All tables in `public` schema have RLS policies ensuring users can only access their own data:

```sql
-- Example: Users can only read/update their own user profile
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- Example: Users can only view their own audits
CREATE POLICY "Users can view own audits"
  ON public.audit_results FOR SELECT
  USING (auth.uid() = user_id);
```

---

## API Setup (FastAPI Backend)

### VPS Details

| Property | Value |
|----------|-------|
| **IP Address** | `140.99.254.83` |
| **Provider** | Linode or equivalent |
| **SSH Access** | `ssh root@140.99.254.83` |
| **Primary Domain** | `api.websler.pro` |

### FastAPI Configuration

**Service Name:** `websler-pro-api`
**Running Command:**
```bash
/usr/bin/python3 -m uvicorn fastapi_server:app \
  --host 0.0.0.0 \
  --port 443 \
  --ssl-keyfile=/etc/ssl/private/api.websler.pro.key \
  --ssl-certfile=/etc/ssl/certs/api.websler.pro.crt
```

**Process ID Check:**
```bash
ps aux | grep uvicorn
```

**Port Mappings:**

| Port | Protocol | Service | Status |
|------|----------|---------|--------|
| 443 | HTTPS | FastAPI Backend | Active |
| 8000 | HTTP | Development (local only) | Inactive |

### Environment Variables on VPS

```bash
ANTHROPIC_API_KEY=sk-ant-... # Set in systemd service
SUPABASE_URL=https://vwnbhsmfpxdfcvqnzddc.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc... # From .env
```

### API Endpoints

| Endpoint | Method | Purpose | Auth Required |
|----------|--------|---------|---------------|
| `/api/health` | GET | Health check | No |
| `/api/analyze` | POST | Analyze website (Websler) | Yes |
| `/api/audit` | POST | Full 10-point audit | Yes |
| `/api/pdf` | POST | Generate summary PDF | Yes |
| `/api/audit/generate-pdf/{id}/{type}` | POST | Generate audit PDF | Yes |
| `/api/history` | GET | Get user's history | Yes |
| `/api/delete/{id}` | DELETE | Delete analysis | Yes |

---

## SSL/TLS Configuration

### Certificate Details (api.websler.pro)

| Property | Value |
|----------|-------|
| **Domain** | `api.websler.pro` |
| **Certificate Type** | Let's Encrypt (Free) |
| **Cert Path** | `/etc/ssl/certs/api.websler.pro.crt` |
| **Key Path** | `/etc/ssl/private/api.websler.pro.key` |
| **Certbot Managed** | Yes |
| **Auto-Renewal** | Enabled via systemd timer |

### SSL Verification Command

```bash
# Check certificate validity
openssl x509 -in /etc/ssl/certs/api.websler.pro.crt -text -noout | grep -E "Subject:|Not Before|Not After"

# Expected output shows certificate is valid until ~2026
```

### Certificate Renewal

**Automatic Renewal:** Handled by `certbot` timer
**Manual Renewal (if needed):**
```bash
sudo certbot renew --force-renewal -d api.websler.pro
sudo systemctl restart uvicorn  # Restart FastAPI to load new cert
```

**Renewal Schedule:** Let's Encrypt certificates expire in 90 days. Certbot automatically renews at 30 days before expiration.

---

## Flutter Web Deployment

### Firebase Projects

#### Production (websler-pro)

| Property | Value |
|----------|-------|
| **Firebase Project ID** | `websler-pro` |
| **Region** | `us-central1` |
| **Hosting Target** | `websler-pro-production` |
| **URL** | `https://websler.pro` |
| **Domain** | Custom domain (websler.pro) |
| **Status** | Active |

#### Staging (websler-pro-staging)

| Property | Value |
|----------|-------|
| **Firebase Project ID** | `websler-pro` (same project, different target) |
| **Hosting Target** | `websler-pro-staging` |
| **URL** | `https://websler-pro-staging.web.app` |
| **Status** | Active |

### Build Configuration

**Firebase Configuration File:** `firebase.json`
```json
{
  "hosting": [
    {
      "target": "websler-pro-staging",
      "public": "build/web",
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    },
    {
      "target": "websler-pro-production",
      "public": "build/web",
      "rewrites": [
        {
          "source": "**",
          "destination": "/index.html"
        }
      ]
    }
  ]
}
```

**Firebase Targets:** `.firebaserc`
```json
{
  "projects": {
    "default": "websler-pro",
    "production": "websler-pro",
    "staging": "websler-pro-staging"
  },
  "targets": {
    "websler-pro": {
      "hosting": {
        "websler-pro-production": ["websler-pro"],
        "websler-pro-staging": ["websler-pro-staging"]
      }
    },
    "websler-pro-staging": {
      "hosting": {
        "websler-pro-staging": ["websler-pro-staging"]
      }
    }
  }
}
```

### Environment Detection

The app automatically detects environment based on build mode:

**Debug Builds** (flutter run):
- `kDebugMode` = true
- Uses **Staging** Supabase credentials
- API calls to staging backend

**Release Builds** (flutter build web):
- `kDebugMode` = false
- Uses **Production** Supabase credentials
- API calls to production backend

**Configuration File:** `lib/config/environment.dart`
```dart
static const Environment environment = kDebugMode
    ? Environment.staging
    : Environment.production;
```

### Build & Deploy Commands

**Build for Staging (with staging Supabase credentials):**
```bash
cd webaudit_pro_app
flutter clean
flutter pub get
flutter build web --release --dart-define=ENVIRONMENT=staging
```

**Deploy to Staging:**
```bash
firebase deploy --only hosting:websler-pro-staging
```

**Build for Production (with production Supabase credentials):**
```bash
cd webaudit_pro_app
flutter clean
flutter pub get
flutter build web --release --dart-define=ENVIRONMENT=production
```

**Deploy to Production:**
```bash
firebase deploy --only hosting:websler-pro-production
```

**Important:** Always use the `--dart-define=ENVIRONMENT=` flag when building for web to ensure the correct Supabase credentials are embedded in the build. This ensures:
- Staging builds use Staging Supabase (`kmlhslmkdnjakkpluwup`)
- Production builds use Production Supabase (`vwnbhsmfpxdfcvqnzddc`)
- User authentication tokens match the database environment

---

## DNS & Domain Configuration

### Domain Registrar

| Property | Value |
|----------|-------|
| **Registrar** | Hostinger |
| **Primary Domain** | `websler.pro` |
| **Subdomain** | `api.websler.pro` |

### DNS Records

#### Root Domain (websler.pro)

| Type | Name | Value | Purpose |
|------|------|-------|---------|
| A | @ | Firebase IP | Points to Firebase Hosting |
| CNAME | www | websler.pro.web.app | WWW redirect |

**Firebase Hosting IP:** Managed by Firebase (varies, use CNAME)
**Propagation Time:** 24-48 hours after DNS change

#### API Subdomain (api.websler.pro)

| Type | Name | Value | Purpose |
|------|------|-------|---------|
| A | api | 140.99.254.83 | Points to FastAPI VPS |

**VPS IP:** `140.99.254.83`
**Created:** October 30, 2025
**TTL:** 3600 seconds (1 hour)

### DNS Verification

```bash
# Check websler.pro
nslookup websler.pro

# Check api.websler.pro
nslookup api.websler.pro
# Should return: 140.99.254.83

# Verify HTTPS works
curl -I https://api.websler.pro
# Should return: 200 OK with certificate info
```

---

## Environment Configuration

### .env File (Root of webaudit_pro_app)

**Location:** `webaudit_pro_app/.env`
**Git Status:** Added to `.gitignore` (NOT committed)
**Used By:** Dart's `flutter_dotenv` during debug builds only

**Contents:**
```bash
# Supabase Configuration
SUPABASE_URL=https://vwnbhsmfpxdfcvqnzddc.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Backend API Configuration
API_BASE_URL=https://api.websler.pro

# Environment
ENVIRONMENT=development
```

**Note:** Web builds (release) ignore .env and use hardcoded credentials in `lib/config/environment.dart`

### Release Build Configuration

**File:** `lib/config/environment.dart`
**Contains:** Hardcoded Supabase credentials for staging and production
**Reason:** Flutter web builds don't have access to .env files at runtime

**Key Points:**
- Staging credentials are used when `kDebugMode` is true
- Production credentials are used when `kDebugMode` is false
- Web builds (release) always use production credentials
- Mobile builds can override via environment config

### API URL Configuration

**File:** `lib/utils/env_loader.dart`
**Logic:**
1. Try to load `API_BASE_URL` from .env (works in debug)
2. Fall back to hardcoded `https://api.websler.pro` (works in web release)

```dart
static String getApiUrl() {
  // Try .env first (debug builds)
  final envApiUrl = _safeGet('API_BASE_URL');
  if (envApiUrl != null) {
    _cachedApiUrl = envApiUrl;
    return _cachedApiUrl!;
  }

  // Fall back to production API domain (release builds)
  _cachedApiUrl = 'https://api.websler.pro';
  return _cachedApiUrl!;
}
```

---

## Health Checks & Monitoring

### Daily Health Check Procedure

#### 1. API Health
```bash
# Test HTTPS connection to production API
curl -I https://api.websler.pro/api/health

# Expected response: 404 (because /api/health may not exist)
# What matters: Connection succeeds without SSL errors
```

#### 2. Supabase Connection
```bash
# Check if Supabase projects are healthy
# Visit: https://app.supabase.com/

# Look for: ACTIVE_HEALTHY status on both projects
# Production: vwnbhsmfpxdfcvqnzddc
# Staging: kmlhslmkdnjakkpluwup
```

#### 3. Firebase Hosting
```bash
# Test production website
curl -I https://websler.pro

# Test staging website
curl -I https://websler-pro-staging.web.app

# Both should return: 200 OK
```

#### 4. DNS Resolution
```bash
# Verify DNS records
nslookup websler.pro
nslookup api.websler.pro

# Should resolve to correct IPs
```

#### 5. FastAPI Process
```bash
# SSH into VPS
ssh root@140.99.254.83

# Check if FastAPI is running
ps aux | grep uvicorn
# Should show: /usr/bin/python3 -m uvicorn fastapi_server:app ...

# Check if listening on port 443
ss -tlnp | grep 443
# Should show: LISTEN ... python3 ... :443
```

### Log Monitoring

#### VPS Logs
```bash
# SSH into VPS
ssh root@140.99.254.83

# Check FastAPI logs (if using systemd)
sudo journalctl -u websler-api -f

# Or check application logs directly
# Location depends on your setup
```

#### Supabase Logs
```bash
# Visit Supabase Dashboard:
# https://app.supabase.com/project/vwnbhsmfpxdfcvqnzddc/logs/postgres
```

#### Firebase Logs
```bash
# Visit Firebase Console:
# https://console.firebase.google.com/project/websler-pro/hosting

# Check: Performance, Build logs, Errors
```

---

## Emergency Procedures

### Issue: API Returning 503 (Service Unavailable)

**Diagnosis:**
```bash
ssh root@140.99.254.83
ps aux | grep uvicorn
# If no process, FastAPI crashed
```

**Recovery:**
```bash
# Restart FastAPI
sudo systemctl restart websler-api

# Or if using direct uvicorn:
cd /var/www/websler-pro
/usr/bin/python3 -m uvicorn fastapi_server:app \
  --host 0.0.0.0 \
  --port 443 \
  --ssl-keyfile=/etc/ssl/private/api.websler.pro.key \
  --ssl-certfile=/etc/ssl/certs/api.websler.pro.crt
```

---

### Issue: "Invalid API Key" Error (Supabase 401)

**Possible Causes:**
1. Anon key is outdated or rotated
2. Web app using old hardcoded credentials in `lib/config/environment.dart`
3. Service role key expired on backend

**Recovery:**

1. **Check current Supabase keys:**
   ```bash
   # Use Supabase MCP
   mcp call supabase get_anon_key --project_id vwnbhsmfpxdfcvqnzddc
   ```

2. **Update if needed:**
   - Edit `lib/config/environment.dart`
   - Update the `anonKey` in production SupabaseConfig
   - Rebuild: `flutter build web --release`
   - Redeploy: `firebase deploy --only hosting:websler-pro-production`

3. **Update backend (if service role key rotated):**
   - Update `.env` on VPS with new key
   - Restart FastAPI service

---

### Issue: "Mixed Content" Error (HTTPS app calling HTTP API)

**Symptom:** Browser console shows:
```
Mixed Content: The page at 'https://...' was loaded over HTTPS,
but requested an insecure resource 'http://...'
```

**Root Cause:** HTTPS pages cannot call HTTP endpoints for security

**Recovery:**
1. Ensure API is accessible via HTTPS only
2. Update app to use `https://api.websler.pro` (already done)
3. Rebuild and redeploy: `flutter build web --release && firebase deploy`

---

### Issue: SSL Certificate Expired

**Check Certificate:**
```bash
openssl x509 -in /etc/ssl/certs/api.websler.pro.crt -text -noout | grep "Not After"
```

**If Expired:**
```bash
# Renew certificate
sudo certbot renew --force-renewal -d api.websler.pro

# Restart FastAPI
sudo systemctl restart websler-api
```

---

### Issue: Firebase Hosting Not Updating

**Diagnosis:**
```bash
# Check build files exist
ls -la webaudit_pro_app/build/web/ | head -20

# Verify Firebase configuration
cat webaudit_pro_app/firebase.json
cat webaudit_pro_app/.firebaserc
```

**Recovery:**
```bash
# Full clean rebuild and deploy
cd webaudit_pro_app
flutter clean
flutter pub get
flutter build web --release
firebase deploy --only hosting:websler-pro-production --force

# Clear browser cache and do hard refresh (Ctrl+Shift+R)
```

---

### Issue: DNS Not Resolving

**Diagnosis:**
```bash
nslookup api.websler.pro
# Should return: 140.99.254.83

nslookup websler.pro
# Should return: Firebase IP (varies)
```

**Recovery:**
1. Log into Hostinger DNS management
2. Verify A records are correctly configured
3. Wait 24-48 hours for full propagation
4. Test with: `nslookup -type=A api.websler.pro`

---

### Full System Restart Procedure

If all services are down, restart in order:

```bash
# 1. SSH into VPS and restart FastAPI
ssh root@140.99.254.83
sudo systemctl restart websler-api

# 2. Verify API is responding
curl -I https://api.websler.pro

# 3. Check Supabase (no restart needed)
# Visit: https://app.supabase.com/

# 4. Redeploy Firebase (if needed)
cd /path/to/webaudit_pro_app
firebase deploy --only hosting:websler-pro-production

# 5. Verify all endpoints
curl -I https://websler.pro
curl -I https://websler-pro-staging.web.app
curl -I https://api.websler.pro
```

---

## Maintenance Schedule

### Daily (Automated)
- ✅ Let's Encrypt certificate auto-renewal checks (Certbot)
- ✅ Supabase automated backups
- ✅ Firebase CDN cache warming

### Weekly
- [ ] Check health endpoints
- [ ] Review Supabase logs for errors
- [ ] Check certificate expiration
- [ ] Verify DNS propagation

### Monthly
- [ ] Review API logs for patterns
- [ ] Check database query performance
- [ ] Update dependencies if available
- [ ] Test disaster recovery procedures

### Quarterly
- [ ] Full infrastructure audit
- [ ] Update documentation
- [ ] Security vulnerability scan
- [ ] Backup verification

### Annually
- [ ] Review and update all passwords/keys (if not auto-rotated)
- [ ] Plan capacity upgrades
- [ ] Comprehensive security audit

---

## Quick Reference

### Credentials Location

| Credential | Location | Scope |
|-----------|----------|-------|
| Production Supabase Anon Key | `lib/config/environment.dart` | Hardcoded in build |
| Staging Supabase Anon Key | `lib/config/environment.dart` | Hardcoded in build |
| Supabase Service Role Key | `webaudit_pro_app/.env` | Backend only |
| Anthropic API Key | VPS `.env` | Backend API only |
| Firebase Credentials | `~/.firebaserc` | Local machine |

### Important URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Production App | https://websler.pro | User-facing |
| Staging App | https://websler-pro-staging.web.app | Testing |
| API | https://api.websler.pro | Backend |
| Supabase Production | https://app.supabase.com/project/vwnbhsmfpxdfcvqnzddc | Database |
| Supabase Staging | https://app.supabase.com/project/kmlhslmkdnjakkpluwup | Testing DB |
| Firebase Console | https://console.firebase.google.com/project/websler-pro | Hosting |

### Key IP Addresses

| Service | IP | Notes |
|---------|-----|-------|
| VPS (api.websler.pro) | 140.99.254.83 | Production API |
| Firebase (websler.pro) | Dynamic (CNAME) | Production web |

### Common Commands

```bash
# Health check API
curl -I https://api.websler.pro/api/health

# Check DNS
nslookup api.websler.pro
nslookup websler.pro

# SSH to VPS
ssh root@140.99.254.83

# Deploy staging
firebase deploy --only hosting:websler-pro-staging

# Deploy production
firebase deploy --only hosting:websler-pro-production

# Check FastAPI running
ps aux | grep uvicorn

# Check certificate
openssl x509 -in /etc/ssl/certs/api.websler.pro.crt -text -noout | grep "Not After"
```

---

## Support & Escalation

**For API Issues:**
1. Check VPS at 140.99.254.83
2. Restart FastAPI service
3. Check Anthropic API key

**For Database Issues:**
1. Check Supabase dashboard
2. Verify RLS policies
3. Review database logs

**For Deployment Issues:**
1. Check Firebase console
2. Verify .firebaserc and firebase.json
3. Check build artifacts in build/web

**For SSL Issues:**
1. Verify certificate hasn't expired
2. Check certificate paths on VPS
3. Restart FastAPI to reload certificate

---

**Document Version:** 1.0
**Last Updated:** October 30, 2025
**Next Review:** November 30, 2025
