# WebAudit Pro - Complete Technology Stack Documentation

**Production URL:** https://websler.pro
**Current Version:** 1.2.3
**Last Updated:** November 4, 2025

---

## Table of Contents
1. [Overview](#overview)
2. [Frontend Architecture](#frontend-architecture)
3. [Backend Architecture](#backend-architecture)
4. [Database & Authentication](#database--authentication)
5. [Development Tools & AI](#development-tools--ai)
6. [Infrastructure & Deployment](#infrastructure--deployment)
7. [Architecture Diagram](#architecture-diagram)
8. [Data Flow](#data-flow)
9. [Security](#security)
10. [Monitoring & Error Tracking](#monitoring--error-tracking)

---

## Overview

**WebAudit Pro** (websler.pro) is a professional website auditing and analysis platform that provides:
- AI-powered website summaries (Websler mode)
- 10-point compliance audits (WebAudit Pro mode)
- PDF report generation
- Multi-user authentication with data isolation
- Cross-platform support (Web, iOS, Android, Windows, macOS)

**Architecture Type:** Hybrid cloud architecture with:
- Flutter web frontend (compiled to JavaScript)
- Python FastAPI backend on VPS
- Supabase for database and authentication
- Firebase for CDN/hosting
- Anthropic Claude API for AI analysis

---

## Frontend Architecture

### **Core Technology**
- **Framework:** Flutter 3.5.0 (Google's cross-platform UI toolkit)
- **Language:** Dart 3.5.0
- **Build Target:** Web (compiled to JavaScript via dart2js)
- **Architecture Pattern:** Provider state management with MVVM

### **Flutter Dependencies (pubspec.yaml)**

**UI & Design:**
```yaml
cupertino_icons: ^1.0.8        # iOS-style icons
google_fonts: ^6.1.0           # Raleway font family
fl_chart: ^0.68.0              # Charts for data visualization
```

**State Management & Data:**
```yaml
provider: ^6.0.0               # State management
shared_preferences: ^2.2.0     # Local persistent storage
```

**Network & Backend Communication:**
```yaml
http: ^1.1.0                   # HTTP client for API calls
supabase_flutter: ^1.10.0+2    # Supabase SDK (auth + database)
```

**Utilities:**
```yaml
intl: ^0.19.0                  # Date formatting and internationalization
url_launcher: ^6.1.0           # Open URLs and PDFs in browser
path_provider: ^2.1.0          # Access to file system paths
shelf: ^1.4.1                  # HTTP server for auth callbacks
flutter_dotenv: ^5.1.0         # Environment variable management
```

**Build Tools:**
```yaml
flutter_lints: ^5.0.0                # Code quality rules
flutter_native_splash: ^2.4.0        # Splash screen generator
flutter_launcher_icons: ^0.13.1      # App icon generator
```

### **Frontend Architecture Layers**

```
┌─────────────────────────────────────┐
│         UI Layer (Screens)          │
│  - HomeScreen (Websler summary)     │
│  - HistoryScreen (analysis history) │
│  - SettingsScreen (theme, config)   │
│  - AuthScreens (login/signup)       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      State Management (Provider)     │
│  - AuthService (authentication)      │
│  - ThemeService (light/dark mode)    │
│  - SyncService (offline sync)        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Service Layer (Business)       │
│  - ApiService (backend HTTP calls)   │
│  - AuthService (Supabase auth)       │
│  - SyncService (offline/online sync) │
│  - ConnectivityService (network)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Data Layer (Storage)         │
│  - Supabase (cloud PostgreSQL)       │
│  - SharedPreferences (local cache)   │
│  - Models (WebsiteAnalysis, User)    │
└──────────────────────────────────────┘
```

### **Key Frontend Features**

1. **Responsive Design:**
   - Desktop: 2-column layout with centered content
   - Mobile: Stacked vertical layout
   - Adaptive breakpoint: 800px

2. **Theming:**
   - Light mode (default): #F6F8FF background
   - Dark mode: #0A0E27 background
   - Persistent theme preference via SharedPreferences

3. **Offline Support:**
   - Local caching with SharedPreferences
   - Connectivity monitoring
   - Automatic sync when online

4. **Authentication UI:**
   - Email/password login and signup
   - Session restoration on app restart
   - JWT token management

---

## Backend Architecture

### **Core Technology**
- **Framework:** Python FastAPI (high-performance async web framework)
- **Server:** Uvicorn ASGI server
- **Hosting:** VPS (140.99.254.83, Ubuntu Linux)
- **Process Management:** systemd service (weblser.service)
- **Web Server:** Nginx (reverse proxy + static file serving)

### **Python Dependencies (requirements.txt)**

```python
# Web Framework
fastapi>=0.100.0           # Modern async web framework
uvicorn>=0.23.0            # ASGI server

# HTTP & Scraping
requests==2.31.0           # HTTP client for fetching websites
httpx>=0.27.0              # Async HTTP client
beautifulsoup4==4.12.2     # HTML parsing

# AI & NLP
anthropic>=0.39.0          # Claude API for AI summaries/audits

# PDF Generation
reportlab==4.0.9           # PDF creation library

# Monitoring
sentry-sdk[fastapi]>=1.50.0  # Error tracking and monitoring

# Testing & Automation
playwright>=1.40.0         # Browser automation for testing

# Templating
jinja2>=3.1.0             # Template engine
```

### **Backend Service Architecture**

```
┌─────────────────────────────────────┐
│        Nginx (Port 80/443)           │
│  - SSL termination (Let's Encrypt)   │
│  - Static file serving               │
│  - Reverse proxy to FastAPI          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     FastAPI (Port 8000 internal)     │
│  - REST API endpoints                │
│  - CORS middleware                   │
│  - Request validation                │
│  - Error handling                    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Business Logic Layer          │
│  - WebsiteAnalyzer (AI summaries)    │
│  - ComplianceAuditor (10-point)      │
│  - PDFGenerator (reports)            │
│  - AuthMiddleware (JWT validation)   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       External Services Layer        │
│  - Anthropic Claude API              │
│  - Supabase (database + auth)        │
│  - Sentry (error tracking)           │
└──────────────────────────────────────┘
```

### **API Endpoints**

**Authentication:**
```
POST /auth/token       - Get JWT token (email/password)
POST /auth/refresh     - Refresh expired token
```

**Analysis:**
```
POST /summary          - Generate Websler AI summary
POST /audit            - Run 10-point compliance audit
POST /upgrade          - Upgrade summary to audit
```

**Reports:**
```
POST /report/pdf       - Generate branded PDF report
GET  /report/{id}      - Download PDF by ID
```

**History:**
```
GET  /history          - Get user's analysis history
DELETE /history/{id}   - Delete specific analysis
```

**Health:**
```
GET  /health           - Service health check
GET  /version          - API version info
```

### **Backend File Structure**

```
/home/weblser/
├── .env                    # Environment variables (secrets)
├── requirements.txt        # Python dependencies
├── analyzer.py             # Main FastAPI application
├── weblser_logo.png       # Logo for PDF headers
├── jumoki_coloured_transparent_bg.png
└── systemd/
    └── weblser.service     # Service definition
```

---

## Database & Authentication

### **Supabase (PostgreSQL + Auth)**

**Project:** websler-pro
**Project Reference:** vwnbhsmfpxdfcvqnzddc
**Region:** US-East (Virginia)
**Plan:** Pro ($25/month)

### **Database Schema (PostgreSQL)**

```sql
-- Users table (extends Supabase auth)
CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT NOT NULL,
    full_name TEXT,
    company_name TEXT,
    company_details TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Website analyses (summaries + audits)
CREATE TABLE website_analyses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    url TEXT NOT NULL,
    analysis_type TEXT NOT NULL CHECK (analysis_type IN ('summary', 'audit')),
    title TEXT,
    summary TEXT,
    audit_results JSONB,           -- 10-point audit scores
    recommendations JSONB,           -- Individual recommendations
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PDF generation tracking
CREATE TABLE pdf_generations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    analysis_id UUID REFERENCES website_analyses(id),
    pdf_url TEXT,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Row-Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE website_analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE pdf_generations ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can view own analyses"
    ON website_analyses FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can view own PDFs"
    ON pdf_generations FOR SELECT
    USING (auth.uid() = user_id);
```

### **Authentication Flow**

```
User enters email/password
         │
         ▼
┌─────────────────────┐
│ Supabase Auth API   │
│  - Validates creds  │
│  - Issues JWT       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Flutter Frontend   │
│  - Stores JWT       │
│  - Sets auth header │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  FastAPI Backend    │
│  - Validates JWT    │
│  - Extracts user_id │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Supabase Database  │
│  - RLS filters data │
│  - Returns user's   │
│    analyses only    │
└─────────────────────┘
```

---

## Development Tools & AI

### **Claude Code (Primary Development Tool)**

**What it is:** AI-powered coding assistant by Anthropic
**Version:** Using Sonnet 4.5 model
**Configuration:** C:\Users\Ntro\AppData\Roaming\Claude\claude_desktop_config.json

**Capabilities:**
- Full codebase understanding and navigation
- Code generation and refactoring
- Git operations and deployment automation
- Testing and debugging
- Documentation generation
- Real-time collaboration with developer

### **Model Context Protocol (MCP) Servers**

MCPs extend Claude Code with specialized tools and integrations:

#### **1. Sentry MCP** (`mcp__sentry__*`)
**Purpose:** Error tracking and monitoring
**Tools Available:**
- `search_issues` - Find errors and exceptions
- `get_issue_details` - Get stack traces and event data
- `search_events` - Query error logs by time/filter
- `update_issue` - Resolve or assign issues
- `analyze_issue_with_seer` - AI root cause analysis

**Usage:** Monitor production errors, diagnose crashes

#### **2. Supabase MCP** (`mcp__supabase__*`)
**Purpose:** Database management and queries
**Configuration:**
```json
{
  "command": "npx -y @supabase/mcp-server-supabase@latest",
  "args": ["--project-ref=gxwmzhpigfozryjwivyi"],
  "env": {
    "SUPABASE_ACCESS_TOKEN": "[REDACTED]"
  }
}
```

**Tools Available:**
- `list_projects` - List Supabase projects
- `execute_sql` - Run SQL queries
- `apply_migration` - Apply database migrations
- `list_tables` - Inspect schema
- `get_advisors` - Security and performance recommendations
- `search_docs` - Search Supabase documentation

**Usage:** Schema changes, RLS policy creation, data queries

#### **3. Sequential Thinking MCP** (`mcp__sequential-thinking__*`)
**Purpose:** Complex multi-step problem solving
**Configuration:**
```json
{
  "command": "npx -y @modelcontextprotocol/server-sequential-thinking@latest"
}
```

**Tools Available:**
- `sequentialthinking` - Step-by-step reasoning with hypothesis generation and verification

**Usage:** Debugging complex issues, architecture decisions

#### **4. Playwright MCP** (`mcp__playwright__*`)
**Purpose:** Browser automation and testing
**Configuration:**
```json
{
  "command": "npx -y @executeautomation/playwright-mcp-server"
}
```

**Tools Available:**
- `browser_navigate` - Navigate to URLs
- `browser_snapshot` - Capture accessibility tree
- `browser_click` - Interact with elements
- `browser_console_messages` - Read console logs
- `browser_take_screenshot` - Capture visuals
- `browser_network_requests` - Monitor HTTP traffic

**Usage:** End-to-end testing, production verification

#### **5. Filesystem MCP** (`mcp__fs-app__*`, `mcp__fs-websler__*`)
**Purpose:** File operations with permissions
**Tools Available:**
- `read_text_file` - Read source code
- `write_file` - Create/overwrite files
- `edit_file` - Line-based edits
- `list_directory` - Browse file structure
- `search_files` - Find files by pattern
- `directory_tree` - Get recursive structure

**Usage:** Code editing, file management

#### **6. Fetch MCP** (`mcp__fetch__*`)
**Purpose:** Web content fetching and scraping
**Tools Available:**
- `fetch` - Download web pages as markdown

**Usage:** Research, documentation access, web scraping

### **AI Agents & Sub-Agents**

Claude Code uses specialized agents for complex tasks:

**Available Agents:**
- `general-purpose` - Multi-step tasks, codebase exploration
- `sentry-reader` - Error analysis and debugging
- `supabase-specialist` - Database schema design, RLS policies
- `smoke-tester` - Post-deployment validation
- `flutter-build-helper` - iOS/Android/Windows builds
- `log-detective` - Multi-source log correlation
- `api-health-checker` - Endpoint health monitoring
- `env-config-validator` - Environment variable audits
- `session-context-loader` - Project state restoration

**Agent Workflow Example:**
```
User: "Deploy to production and verify"
         │
         ▼
┌─────────────────────┐
│ flutter-build-helper│
│  - Builds Flutter   │
│  - Signs app        │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   smoke-tester      │
│  - Runs health      │
│    checks           │
│  - Validates APIs   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  sentry-reader      │
│  - Monitors for     │
│    new errors       │
└─────────────────────┘
```

---

## Infrastructure & Deployment

### **Production Infrastructure**

```
┌──────────────────────────────────────────────────┐
│              USERS / BROWSERS                     │
└────────────────────┬─────────────────────────────┘
                     │
          ┌──────────▼──────────┐
          │   DNS Resolution    │
          │  websler.pro →      │
          │  140.99.254.83      │
          └──────────┬──────────┘
                     │
    ┌────────────────▼────────────────┐
    │         VPS Server              │
    │    140.99.254.83 (Ubuntu)       │
    │                                 │
    │  ┌───────────────────────────┐  │
    │  │  Nginx (Port 443 SSL)     │  │
    │  │  - Let's Encrypt certs    │  │
    │  │  - /var/www/websler.pro   │  │
    │  │    (Flutter web build)    │  │
    │  └──────────┬────────────────┘  │
    │             │                    │
    │  ┌──────────▼────────────────┐  │
    │  │  FastAPI (Port 8000)      │  │
    │  │  - systemd service        │  │
    │  │  - /home/weblser/         │  │
    │  └──────────┬────────────────┘  │
    └─────────────┼────────────────────┘
                  │
    ┌─────────────▼────────────────┐
    │     External Services        │
    │                              │
    │  ┌────────────────────────┐  │
    │  │  Supabase PostgreSQL   │  │
    │  │  vwnbhsmfpxdfcvqnzddc  │  │
    │  └────────────────────────┘  │
    │                              │
    │  ┌────────────────────────┐  │
    │  │  Anthropic Claude API  │  │
    │  │  (AI summaries/audits) │  │
    │  └────────────────────────┘  │
    │                              │
    │  ┌────────────────────────┐  │
    │  │  Sentry (Monitoring)   │  │
    │  │  Error tracking        │  │
    │  └────────────────────────┘  │
    │                              │
    │  ┌────────────────────────┐  │
    │  │  Firebase Hosting      │  │
    │  │  (CDN fallback)        │  │
    │  └────────────────────────┘  │
    └───────────────────────────────┘
```

### **VPS Configuration**

**Server Details:**
- IP: 140.99.254.83
- OS: Ubuntu Linux
- User: dean (sudo access)
- SSH: Key-based authentication

**Nginx Configuration:**
```nginx
# /etc/nginx/sites-enabled/websler.pro
server {
    server_name websler.pro www.websler.pro;
    root /var/www/websler.pro;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/javascript application/json;

    # Cache static assets (1 year)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Flutter web routing (SPA)
    location / {
        try_files $uri $uri/ /index.html;
    }

    # SSL via Let's Encrypt
    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/websler.pro/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/websler.pro/privkey.pem;
}
```

**Systemd Service:**
```ini
# /etc/systemd/system/weblser.service
[Unit]
Description=WebAudit Pro FastAPI Backend
After=network.target

[Service]
Type=simple
User=dean
WorkingDirectory=/home/weblser
EnvironmentFile=/home/weblser/.env
ExecStart=/usr/bin/python3 -m uvicorn analyzer:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Environment Variables (.env):**
```bash
# Supabase
SUPABASE_URL=https://vwnbhsmfpxdfcvqnzddc.supabase.co
SUPABASE_KEY=[ANON_KEY]
SUPABASE_SERVICE_ROLE_KEY=[SERVICE_ROLE_KEY]

# Anthropic
ANTHROPIC_API_KEY=[API_KEY]

# Sentry
SENTRY_DSN=[DSN_URL]
```

### **Firebase Hosting (CDN Backup)**

**Project:** websler-pro
**Targets:**
- `websler-pro-staging` → https://websler-pro-staging.web.app
- `websler-pro-production` → https://websler-pro.web.app

**Deployment:**
```bash
# Build Flutter web app
flutter clean && flutter build web --release

# Deploy to Firebase
npx firebase deploy --only hosting
```

**Configuration (firebase.json):**
```json
{
  "hosting": [
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

### **Deployment Workflow**

```
┌─────────────────────┐
│  Developer Changes  │
│   (Local Machine)   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Git Commit &      │
│   Push to GitHub    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Pre-commit Hook    │
│  - Scans for secrets│
│  - Runs lints       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Flutter Build      │
│  flutter build web  │
└──────────┬──────────┘
           │
    ┌──────┴──────┐
    │             │
    ▼             ▼
┌─────────┐   ┌─────────┐
│ Firebase│   │   VPS   │
│ Hosting │   │  (scp)  │
└─────────┘   └────┬────┘
                   │
                   ▼
            ┌──────────────┐
            │ Nginx Restart│
            │ systemctl    │
            └──────────────┘
```

---

## Architecture Diagram

### **High-Level System Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                         │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Web App    │  │   iOS App    │  │ Android App  │           │
│  │  (Flutter)   │  │  (Flutter)   │  │  (Flutter)   │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                  │                  │                    │
│         └──────────────────┴──────────────────┘                    │
│                            │                                        │
└────────────────────────────┼────────────────────────────────────────┘
                             │
                             │ HTTPS/REST
                             │
┌────────────────────────────▼────────────────────────────────────────┐
│                      APPLICATION LAYER                              │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                  FastAPI Backend (Python)                   │   │
│  │                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │   │
│  │  │   Auth       │  │   Analysis   │  │   Reports    │     │   │
│  │  │  Middleware  │  │   Engine     │  │   Generator  │     │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
               ┌──────────────┼──────────────┐
               │              │              │
               ▼              ▼              ▼
┌────────────────────┐ ┌──────────────┐ ┌──────────────┐
│   Supabase         │ │  Anthropic   │ │   Sentry     │
│  (PostgreSQL)      │ │  Claude API  │ │  (Monitoring)│
│                    │ │              │ │              │
│  - User data       │ │  - Summaries │ │  - Errors    │
│  - Analyses        │ │  - Audits    │ │  - Alerts    │
│  - Authentication  │ │  - NLP       │ │  - Analytics │
└────────────────────┘ └──────────────┘ └──────────────┘
```

---

## Data Flow

### **User Authentication Flow**

```
1. User enters credentials
   └─> Frontend: lib/screens/auth/login_screen.dart
       └─> Service: lib/services/auth_service.dart
           └─> Supabase Auth API: signInWithPassword()
               └─> Returns: JWT token + user data
                   └─> Frontend stores: SharedPreferences
                       └─> ApiService sets: Authorization header
                           └─> All subsequent API calls include token
```

### **Website Analysis Flow (Websler Summary)**

```
1. User enters URL in HomeScreen
   └─> Frontend validates URL format
       └─> ApiService.generateWebslerSummary(url)
           └─> POST /summary to FastAPI backend
               └─> Backend fetches website HTML
                   └─> BeautifulSoup extracts content
                       └─> Anthropic Claude API analyzes
                           └─> Returns AI summary
                               └─> Backend saves to Supabase
                                   └─> Frontend displays result
                                       └─> User can upgrade to audit
```

### **Compliance Audit Flow (WebAudit Pro)**

```
1. User clicks "Upgrade to Pro"
   └─> ApiService.upgradeToAudit(summaryId)
       └─> POST /audit to FastAPI backend
           └─> Backend fetches detailed website data
               └─> Runs 10 compliance checks:
                   1. Performance
                   2. SEO
                   3. Accessibility
                   4. Security
                   5. Mobile Responsiveness
                   6. Content Quality
                   7. User Experience
                   8. Technical SEO
                   9. Social Integration
                   10. Analytics & Tracking
               └─> Anthropic Claude analyzes each
                   └─> Generates recommendations
                       └─> Saves to Supabase
                           └─> Returns JSON results
                               └─> Frontend displays audit results
                                   └─> User can download PDF
```

### **PDF Generation Flow**

```
1. User clicks "Download PDF"
   └─> ApiService.generatePdfUnified(analysisId)
       └─> POST /report/pdf to FastAPI
           └─> Backend fetches analysis from Supabase
               └─> ReportLab creates PDF:
                   - Header: Websler + Jumoki logos
                   - Body: Analysis details
                   - Footer: Company details
               └─> Saves to VPS disk
                   └─> Returns download URL
                       └─> Frontend opens PDF in browser
```

---

## Security

### **Authentication & Authorization**

**JWT Token Flow:**
- Issued by: Supabase Auth
- Stored: SharedPreferences (Frontend) + HTTP-only cookies
- Transmitted: Authorization: Bearer {token} header
- Validation: FastAPI middleware verifies signature
- Expiration: 1 hour (auto-refresh via Supabase SDK)

**Row-Level Security (RLS):**
```sql
-- Every query automatically filtered by user_id
CREATE POLICY "users_select_own"
    ON website_analyses FOR SELECT
    USING (auth.uid() = user_id);
```

**API Key Protection:**
- Backend secrets in: /home/weblser/.env (chmod 600)
- Frontend: No secrets (uses anon key only)
- Git hooks: Prevent secret commits
- Rotation: Documented process for key compromise

### **Data Isolation**

**Multi-Tenant Architecture:**
- Each user has unique UUID (user_id)
- All database queries filtered by user_id via RLS
- Frontend never sees other users' data
- Backend validates JWT and extracts user_id

### **HTTPS/SSL**

- Certificate: Let's Encrypt (auto-renewal)
- Protocol: TLS 1.2+
- Nginx: Strong cipher suites
- HSTS: Enabled

---

## Monitoring & Error Tracking

### **Sentry Integration**

**What it monitors:**
- Frontend exceptions (Flutter errors)
- Backend API errors (FastAPI exceptions)
- Performance metrics (response times)
- User sessions (affected user count)

**Configuration:**
```python
# Backend
import sentry_sdk
sentry_sdk.init(
    dsn="[SENTRY_DSN]",
    traces_sample_rate=1.0,
    profiles_sample_rate=1.0,
)
```

**Alert Rules:**
- Email on critical errors (500s)
- Slack webhook for production issues
- Daily digest of unresolved issues

### **Health Monitoring**

**Endpoints:**
```
GET /health - Backend service health
  Returns: {"status": "ok", "timestamp": "2025-11-04T..."}

GET /version - API version info
  Returns: {"version": "1.2.3", "build": "2025-11-04"}
```

**Automated Checks:**
- Smoke tests after deployment
- Uptime monitoring via smoke-tester agent
- Database connectivity validation

---

## Development Workflow

### **Local Development**

```bash
# Frontend (Flutter)
cd webaudit_pro_app
flutter pub get
flutter run -d chrome

# Backend (Python)
cd weblser
pip install -r requirements.txt
python analyzer.py
```

### **Testing**

**Frontend:**
```bash
flutter test                 # Unit tests
flutter test integration_test/  # Integration tests
```

**Backend:**
```bash
pytest tests/                # Unit tests
playwright test              # E2E tests
```

### **Code Quality**

- **Linting:** flutter_lints (Flutter), flake8 (Python)
- **Formatting:** dart format, black (Python)
- **Type Safety:** Dart null safety, Python type hints
- **Git Hooks:** Pre-commit secret scanning

### **Version Control**

- **Repository:** https://github.com/Ntrospect/websler
- **Branch Strategy:** main (production)
- **Commits:** Conventional commits format
- **Co-authored:** Human + Claude Code

---

## Summary

**WebAudit Pro** is a modern full-stack application leveraging:

✅ **Frontend:** Flutter web (cross-platform, performant)
✅ **Backend:** Python FastAPI (async, scalable)
✅ **Database:** Supabase PostgreSQL (RLS, auth)
✅ **AI:** Anthropic Claude 4.5 Sonnet (analysis)
✅ **Infrastructure:** VPS + Firebase (hybrid cloud)
✅ **Development:** Claude Code + MCPs (AI-assisted)
✅ **Security:** JWT, RLS, HTTPS, secret management
✅ **Monitoring:** Sentry (real-time error tracking)

**Key Strengths:**
- Cross-platform (web, iOS, Android, Windows, macOS)
- Multi-user with data isolation
- Offline-capable with sync
- AI-powered analysis
- Professional PDF reports
- Scalable architecture
- Modern development workflow

**Production Status:** ✅ Live at https://websler.pro

---

**Document Version:** 1.0
**Last Updated:** November 4, 2025
**Maintained By:** Claude Code + Development Team
