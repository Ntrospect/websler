# WebAudit Pro - Tech Stack Quick Reference

**Production:** https://websler.pro | **Version:** 1.2.3 | **Updated:** Nov 4, 2025

---

## 🎯 One-Liner

*Cross-platform website auditing SaaS built with **Flutter** frontend, **Python FastAPI** backend, **Supabase** database, and **Claude AI** analysis engine.*

---

## 📦 Core Stack

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| **Frontend** | Flutter (Dart) | 3.5.0 | Cross-platform UI |
| **Backend** | Python FastAPI | Latest | REST API server |
| **Database** | Supabase PostgreSQL | Pro | User data + auth |
| **AI Engine** | Anthropic Claude | Sonnet 4.5 | Website analysis |
| **Web Server** | Nginx | 1.18.0 | Reverse proxy + SSL |
| **Hosting** | VPS + Firebase | - | Hybrid cloud |
| **Development** | Claude Code | Latest | AI coding assistant |

---

## 🔧 Key Dependencies

### Frontend (Flutter)
```yaml
supabase_flutter: ^1.10.0+2    # Auth + database SDK
provider: ^6.0.0                # State management
google_fonts: ^6.1.0            # Typography (Raleway)
fl_chart: ^0.68.0               # Data visualization
http: ^1.1.0                    # API communication
```

### Backend (Python)
```python
fastapi                  # Web framework
anthropic>=0.39.0       # Claude AI API
reportlab==4.0.9        # PDF generation
sentry-sdk[fastapi]     # Error monitoring
beautifulsoup4==4.12.2  # HTML parsing
```

---

## 🏗️ Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTPS
       ▼
┌─────────────┐      ┌──────────────┐
│    Nginx    │─────→│   FastAPI    │
│  (SSL/CDN)  │      │  (Port 8000) │
└─────────────┘      └──────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
  ┌──────────┐      ┌──────────────┐    ┌──────────┐
  │ Supabase │      │ Anthropic AI │    │  Sentry  │
  │   (DB)   │      │   (Claude)   │    │ (Monitor)│
  └──────────┘      └──────────────┘    └──────────┘
```

---

## 🔐 Security

- **Auth:** JWT tokens via Supabase Auth
- **Data Isolation:** Row-Level Security (RLS)
- **SSL:** Let's Encrypt (auto-renewal)
- **Secrets:** Environment variables (`.env`)
- **Git:** Pre-commit hooks block secret commits

---

## 🌐 Infrastructure

**VPS Server (140.99.254.83):**
- OS: Ubuntu Linux
- User: `dean` (sudo)
- Service: `systemd` (weblser.service)
- Frontend: `/var/www/websler.pro`
- Backend: `/home/weblser/`

**Firebase Hosting:**
- Primary: `websler-pro-production`
- Staging: `websler-pro-staging`
- CDN: Global edge caching

---

## 🤖 Development Tools

### Claude Code (AI Assistant)
- Model: Sonnet 4.5
- Role: Full-stack development, deployment, testing
- Config: `~/.config/claude-code/`

### MCPs (Model Context Protocol)
1. **Sentry MCP** - Error tracking
2. **Supabase MCP** - Database management
3. **Playwright MCP** - Browser testing
4. **Sequential Thinking MCP** - Complex problem solving
5. **Filesystem MCP** - Code editing
6. **Fetch MCP** - Web scraping

### Specialized Agents
- `flutter-build-helper` - iOS/Android builds
- `smoke-tester` - Post-deployment validation
- `sentry-reader` - Error diagnosis
- `supabase-specialist` - Schema migrations
- `api-health-checker` - Uptime monitoring

---

## 📊 Data Flow

```
User Input (URL)
    ↓
Frontend (Flutter)
    ↓ HTTP POST
Backend (FastAPI)
    ↓ Fetch HTML
BeautifulSoup (Parse)
    ↓ Extract Content
Claude AI (Analyze)
    ↓ Generate Report
Supabase (Save)
    ↓ Return JSON
Frontend (Display)
```

---

## 🚀 Deployment

### Frontend
```bash
flutter clean
flutter build web --release
scp -r build/web/* dean@140.99.254.83:/tmp/websler-web-new/
ssh dean@140.99.254.83 "bash /tmp/deploy-websler.sh"
```

### Backend
```bash
scp .env dean@140.99.254.83:/home/weblser/.env
ssh dean@140.99.254.83 "sudo systemctl restart weblser.service"
```

---

## 📈 Monitoring

- **Error Tracking:** Sentry (real-time alerts)
- **Health Checks:** `/health` endpoint
- **Logs:** systemd journal (`journalctl -u weblser.service`)
- **Database:** Supabase Dashboard

---

## 📞 Key URLs

- **Production:** https://websler.pro
- **Staging:** https://websler-pro-staging.web.app
- **API Docs:** https://websler.pro/docs
- **Supabase:** https://supabase.com/dashboard/project/vwnbhsmfpxdfcvqnzddc
- **GitHub:** https://github.com/Ntrospect/websler

---

## 💡 Quick Commands

```bash
# Check backend status
ssh dean@140.99.254.83 "systemctl status weblser.service"

# View backend logs
ssh dean@140.99.254.83 "journalctl -u weblser.service -n 50"

# Restart backend
ssh dean@140.99.254.83 "sudo systemctl restart weblser.service"

# Test API
curl https://websler.pro/health

# Deploy frontend
flutter build web && npx firebase deploy --only hosting
```

---

**For detailed documentation, see:** `TECH_STACK_COMPLETE.md`
