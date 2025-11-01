# Git Backup Specialist - Sub-Agent Specification

## Overview

**Agent Name**: `git-backup-specialist`
**Purpose**: Create bulletproof Git backups and comprehensive handoff documentation at end of session
**Context Window Impact**: Reduces main session context by 50-100 lines of backup/handoff discussion
**Execution Time**: ~2-3 minutes (deterministic, automated)

---

## Agent Capabilities

### What This Agent Does

1. **Analyzes Session Work**
   - Reviews uncommitted Git changes
   - Identifies files modified during session
   - Extracts key accomplishments and fixes
   - Notes resolved issues (Sentry, bugs, features)

2. **Creates Bulletproof Git Backup**
   - Stages all relevant files
   - Writes descriptive commit messages (50-char summary + detailed body)
   - References issues/fixes (e.g., "Fixes PYTHON-FASTAPI-P")
   - Pushes to GitHub remote
   - Verifies push succeeded

3. **Generates Comprehensive Handoff Document**
   - Creates structured markdown file (`SESSION_HANDOFF_[DATE]_[TOPIC].md`)
   - Includes 9 essential sections (see below)
   - Uses emojis for visual scanning
   - Provides actionable "START HERE" guidance
   - Documents WHY, not just WHAT

4. **Commits Handoff to Git**
   - Adds handoff document to version control
   - Commits with descriptive message
   - Pushes to GitHub
   - Verifies both commits on remote

5. **Reports Back**
   - Summary of commits pushed
   - Handoff document location and size
   - One-sentence next session priority

---

## Agent Inputs (Required)

### Minimum Required Context

```markdown
Session work completed:
- [List of features built, bugs fixed, deployments made]

Files modified:
- [List of changed files with brief description]

Next session priority:
- [1-3 sentences on what to do next]
```

### Optional Enhanced Context

```markdown
Issues resolved:
- [Sentry issue IDs, bug descriptions, GitHub issue numbers]

System changes:
- [Deployments, configuration updates, database migrations]

Testing performed:
- [What was tested, results, coverage]

Known issues:
- [Bugs discovered but not fixed, technical debt identified]
```

---

## Agent Outputs (Guaranteed)

### 1. Git Commits (2 total)

**Commit 1**: Session work
- Descriptive summary (50 chars max)
- Detailed body explaining changes
- References to issues fixed
- Pushed to `origin/main`

**Commit 2**: Handoff document
- Includes handoff markdown file
- Commit message references session topic
- Pushed to `origin/main`

### 2. Handoff Document

**Filename Pattern**: `SESSION_HANDOFF_YYYYMMDD_TOPIC.md`

**Required Sections** (9 total):

1. **🎯 Session Overview**
   - 3-sentence summary of session
   - Status badge (✅ READY / ⏳ IN PROGRESS / ⚠️ NEEDS WORK)
   - Key achievement highlighted
   - Git commits listed

2. **📋 Quick Status Check**
   - "Can I [action] immediately?" with YES/NO answer
   - What to test/verify
   - What was fixed/built
   - What's monitoring the system

3. **🔍 Critical Changes**
   - Problem discovered (if applicable)
   - Root cause analysis
   - Fix applied with before/after code
   - Verification steps

4. **📊 System Status**
   - Frontend status (URL, environment, last deployed)
   - Backend status (URL, service, environment)
   - Database status (project, state, record counts)
   - All with ✅/⚠️/❌ indicators

5. **🧪 Testing Workflow** (if applicable)
   - Step-by-step testing instructions
   - Expected results for each step
   - Verification queries (SQL, API calls)
   - Success criteria

6. **🚀 Next Steps**
   - **Immediate** (next session - START HERE)
   - **Short Term** (this week)
   - **Medium Term** (following sessions)
   - **Long Term** (future enhancements)
   - Each with priority indicators (🔥/⚠️/📝)

7. **📞 Quick Reference**
   - Important URLs (staging, production, dashboards)
   - Common commands (frontend, backend, database)
   - Credentials locations (NOT values)
   - MCP server status (if applicable)

8. **🎯 IMMEDIATE ACTION**
   - Highlighted "START HERE" section
   - 3-5 bullet points of exact steps
   - Expected outcome
   - Time estimate

9. **✨ Session Summary**
   - What was accomplished (bulleted list)
   - System health indicators
   - Critical achievements highlighted
   - Commits and documentation created
   - Next session focus

### 3. Verification Report

```markdown
✅ Bulletproof Backup Complete!

Git Commits Pushed (2 total):
- [hash] - [commit message 1]
- [hash] - [commit message 2]

Handoff Document Created:
- File: SESSION_HANDOFF_YYYYMMDD_TOPIC.md
- Size: [N] lines
- Location: [path]

GitHub Status:
- Branch: main
- Status: Up to date with origin/main ✅

Next Session Priority:
[One sentence on what to do first]
```

---

## Agent Workflow (Internal)

### Phase 1: Discovery (30 seconds)

```bash
# Gather session context
git status
git diff
git log --oneline -5

# Identify modified files
git diff --name-only
git diff --cached --name-only

# Check for uncommitted work
git status --short
```

### Phase 2: Git Backup (60 seconds)

```bash
# Stage changes
git add [files]

# Create commit with structured message
git commit -m "Summary (50 chars)

Detailed body:
- What changed
- Why it changed
- What issues it fixes

Fixes [ISSUE-ID]
"

# Push to GitHub
git push origin main

# Verify push
git log --oneline -1
git status
```

### Phase 3: Handoff Generation (45 seconds)

```markdown
# Generate handoff document
# Use template with 9 required sections
# Fill in context from session inputs
# Add emojis, code blocks, verification steps
# Timestamp and metadata
```

### Phase 4: Commit Handoff (30 seconds)

```bash
# Add handoff document
git add SESSION_HANDOFF_*.md

# Commit
git commit -m "docs: Add comprehensive session handoff ([TOPIC])

[Summary of session work]
"

# Push
git push origin main
```

### Phase 5: Report (15 seconds)

```markdown
# Generate verification report
# Show commit hashes
# Show file location and size
# Highlight next session priority
```

**Total Time**: ~3 minutes

---

## Agent Guidelines

### Commit Message Style

**Summary Line** (50 chars max):
- Start with type: `feat:`, `fix:`, `docs:`, `chore:`
- Imperative mood: "Add feature" not "Added feature"
- No period at end
- Capitalize first word

**Body**:
- Wrap at 72 characters
- Explain WHAT and WHY, not HOW
- Separate paragraphs with blank lines
- Reference issues: `Fixes PYTHON-FASTAPI-P`
- List changes with bullet points or dashes

**Example**:
```
feat: Add three-tab History screen organization

- Summary tab for quick AI summaries (blue icon)
- WebAudit Pro tab for 10-point audits (green icon)
- Compliance tab for regulatory reports (purple icon)
- Auto-refresh on app resume (WidgetsBindingObserver)
- Pull-to-refresh per tab
- Type-specific actions and empty states

Fixes multiple UX issues with history organization
Improves user navigation and content discovery
```

### Handoff Document Style

**Language**:
- Second person ("You can test...") for instructions
- First person plural ("We fixed...") for session summary
- Present tense for current state
- Past tense for completed work

**Formatting**:
- Use emojis for section headers (visual scanning)
- Code blocks for commands (```bash, ```sql, ```env)
- Checkbox lists for status (✅ ⏳ ❌)
- Tables for structured data
- Bold for emphasis, NOT ALL CAPS

**Content**:
- Document WHY, not just WHAT
- Include verification steps for everything
- Provide before/after comparisons
- Link to related documents
- Keep secrets safe (locations only, never values)

### Security Guidelines

**NEVER Include**:
- API keys or tokens (actual values)
- Database passwords
- JWT tokens
- Service role keys
- Private URLs with embedded credentials

**DO Include**:
- Locations of secret files (`.env`, `credentials.json`)
- Names of environment variables (without values)
- Commands to verify secrets exist
- Public URLs and dashboard links

**Example (GOOD)**:
```env
# Frontend .env location
SUPABASE_URL=https://kmlhslmkdnjakkpluwup.supabase.co
SUPABASE_ANON_KEY=[stored in .env - see file]
```

**Example (BAD)**:
```env
# DON'T DO THIS!
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Tools Required

The agent needs access to these tools:

1. **Bash** - Git operations (status, add, commit, push, log)
2. **Read** - Check existing files, read previous handoffs
3. **Write** - Create handoff document
4. **Glob** - Find modified files, search for patterns
5. **TodoWrite** - Track backup workflow steps (optional)

---

## Error Handling

### Common Issues & Solutions

**Issue 1**: Nothing to commit
```bash
# Check for uncommitted changes
git status
# If truly nothing changed, skip commit but still create handoff
```

**Issue 2**: Merge conflicts on push
```bash
# Pull first
git pull --rebase origin main
# Resolve conflicts if any
git push origin main
```

**Issue 3**: Large handoff document (>1000 lines)
```markdown
# Consider splitting into multiple documents:
# - SESSION_HANDOFF_YYYYMMDD_MAIN.md (overview)
# - SESSION_DETAILS_YYYYMMDD_SENTRY.md (detailed analysis)
# - SESSION_TESTING_YYYYMMDD.md (testing workflows)
```

**Issue 4**: Missing context for handoff
```markdown
# Ask user for clarification:
"I need more context for the handoff document:
- What was the primary goal of this session?
- What issues were resolved?
- What should be tested next?"
```

---

## Quality Checklist

Before finishing, the agent verifies:

### Git Backup
- [ ] All relevant files staged
- [ ] Commit message follows style guide
- [ ] Commit message references issues/fixes
- [ ] Pushed to origin/main successfully
- [ ] Remote branch is up to date

### Handoff Document
- [ ] All 9 required sections present
- [ ] "IMMEDIATE ACTION" section is clear
- [ ] No secrets exposed (keys, tokens, passwords)
- [ ] Code blocks have language specified
- [ ] Commands are copy-paste ready
- [ ] Timestamps included
- [ ] File size reasonable (<1500 lines)

### Verification
- [ ] Both commits visible in `git log`
- [ ] Handoff file exists on filesystem
- [ ] GitHub remote shows both commits
- [ ] User receives verification report

---

## Example Invocation

### Minimal Input

```markdown
Using Task tool with subagent_type="git-backup-specialist":

Create bulletproof Git backup and handoff document.

Session work:
- Fixed environment mismatch (frontend → staging)
- Deployed to Firebase staging
- Reset database

Files modified:
- .env (staging credentials)
- .gitignore (Python rules)

Next: End-to-end testing workflow
```

### Enhanced Input

```markdown
Using Task tool with subagent_type="git-backup-specialist":

Create bulletproof Git backup and handoff document.

Session work completed:
- Integrated Sentry MCP for error monitoring
- Discovered and fixed critical environment mismatch
- Frontend was using production Supabase, backend using staging
- Updated frontend .env to staging credentials
- Rebuilt and deployed to Firebase staging (29.1s build)
- Resolved Sentry issue PYTHON-FASTAPI-P
- Reset database for fresh testing (0 users, 0 records)
- Enhanced .gitignore with Python/venv rules

Issues resolved:
- PYTHON-FASTAPI-P: User profile not found (environment mismatch)
- PYTHON-FASTAPI-3: Invalid Claude model (already fixed previously)

System changes:
- Frontend: Deployed to https://websler-pro-staging.web.app
- Backend: Running on VPS (no changes needed)
- Database: Staging project kmlhslmkdnjakkpluwup (emptied)

Files modified:
- webaudit_pro_app/.env (staging Supabase credentials)
- webaudit_pro_app/.gitignore (Python-specific ignores)

Testing performed:
- Verified environment alignment (frontend + backend both staging)
- Checked Sentry (0 FK errors in 24 hours)
- Confirmed database cascade delete worked

Known issues:
- Port 443 binding conflict (204 events) - needs VPS investigation
- JSON parsing errors in compliance audits (20 events) - needs error handling

Next session priority:
- Execute end-to-end testing workflow (Steps 1-6)
- Create new account, test Summary → Audit → Compliance
- Verify no "User profile not found" errors
- Monitor Sentry for any new issues
```

---

## Success Metrics

### Quantitative
- **Time to backup**: <3 minutes
- **Handoff completeness**: 9/9 sections present
- **Git commits**: 2 pushed successfully
- **Document size**: 500-1500 lines (ideal)
- **Next session startup time**: <2 minutes to full context

### Qualitative
- User can start next session without questions
- All critical context preserved
- Actionable next steps provided
- Verification steps included
- No secrets exposed

---

## Future Enhancements

### V2 Features (Potential)
- Auto-detect session topic from git diff
- Generate commit messages from file changes
- Create visual diagrams (architecture, flows)
- Integrate with project management (GitHub Issues, Linear)
- Auto-create GitHub PR with handoff in description
- Slack/email notification with handoff summary

### V3 Features (Advanced)
- Multi-session rollup (weekly summaries)
- Auto-detect regression risks from changes
- Suggest test cases based on code changes
- Generate changelog for releases
- Create knowledge base articles from handoffs

---

## Appendix: Template Structure

See `git-backup-specialist-prompt.md` for the complete prompt template that implements this specification.

---

**Version**: 1.0.0
**Last Updated**: November 1, 2025
**Author**: Claude (Sonnet 4.5)
**Status**: Ready for production use
