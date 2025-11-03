---
name: Get Up To Speed
---

# Get-Up-To-Speed Specialist - Sub-Agent Specification

**Agent Name**: `get-up-to-speed`
**Agent Type**: Session Startup Context Loader
**Version**: 1.0.0
**Created**: November 2, 2025
**Status**: ✅ Ready for Use

---

## Overview

The **get-up-to-speed** agent is a specialized sub-agent designed to rapidly load project context at the START of a development session, minimizing context loss and enabling developers to resume work immediately.

### Purpose

When you invoke this agent at session start, it will:
1. Find and parse the most recent session handoff document
2. Extract critical startup information (last work, blockers, immediate actions)
3. Check current git state (branch, commits, uncommitted changes)
4. Scan project documentation (DEV_HANDOFF.md, CLAUDE.md)
5. Generate a concise startup summary with actionable next steps

**Execution Time**: ~80 seconds (deterministic, automated)
**Context Window Impact**: Minimal - loads only critical info without reading full handoffs
**Complementary Agent**: Works with **git-backup-specialist** to create complete session workflow loop

### Session Workflow Loop

```
End of Session → git-backup-specialist → Create Backup & Handoff
                                              ↓
                                         Push to Git
                                              ↓
                                         New Session
                                              ↓
Start of Session → get-up-to-speed → Load Context & Resume Work
```

---

## Agent Capabilities

### What This Agent Does

#### 1. Context Discovery (20 seconds)
- Finds most recent `SESSION_HANDOFF_*.md` file in project directory
- Checks git status (current branch, recent commits, uncommitted changes)
- Identifies working directory and project environment
- Detects staging vs production indicators

**Tools Used**: Glob (find files), Bash (git commands)

#### 2. Session Analysis (25 seconds)
- Parses most recent handoff for key sections:
  - 🎯 Session Overview (status, achievement, key commit)
  - 📋 Quick Status Check (what can I do now?)
  - 🎯 IMMEDIATE ACTION (START HERE section)
  - 📊 System Status (frontend/backend/database indicators)
  - 🚀 Next Steps (prioritized task list)
  - ⚠️ Known Issues (blockers, warnings)

**Tools Used**: Read (parse handoff)

#### 3. Historical Context (15 seconds)
- Reads DEV_HANDOFF.md Quick Start section
- Optionally scans previous 1-2 session handoffs for patterns
- Extracts recurring issues or multi-session progress tracking
- Identifies MCP server configurations

**Tools Used**: Read (parse documentation)

#### 4. Current State Verification (10 seconds)
- Checks for new files created since last handoff
- Identifies uncommitted work (staged/unstaged changes)
- Verifies working directory matches expected project path
- Notes any configuration changes

**Tools Used**: Bash (git diff, git status)

#### 5. Summary Generation (10 seconds)
- Generates concise startup summary (9 sections, detailed below)
- Highlights critical paths and blockers
- Provides 3-5 immediate actions from last handoff
- Lists key URLs, commands, and file paths
- Warns if handoff is stale (>3 days old)

**Tools Used**: Output to console (or optional Write for file)

---

## Agent Inputs

### Input Parameters (All Optional)

The agent supports flexible invocation with auto-detection as the default:

#### Minimal Invocation (Recommended)
```markdown
Get me up to speed on the project.
```

**Auto-Detection Behavior**:
- Project folder: Uses current working directory (`cwd`)
- Most recent handoff: Finds latest `SESSION_HANDOFF_*.md` via glob + date sort
- Environment: Detects from .env files or handoff content
- History depth: Reads only the most recent handoff

#### Enhanced Invocation (Optional Flags)

```markdown
Get me up to speed with:
- full_history: true (read last 3 handoffs vs just 1)
- include_git_diff: true (show uncommitted changes in detail)
- focus: "deployment" (prioritize deployment-related context)
```

**Available Focus Areas**:
- `"deployment"` - Emphasize deployment status, URLs, production readiness
- `"testing"` - Highlight test coverage, testing workflows, verification steps
- `"development"` - Focus on code changes, file locations, development workflow
- `"debugging"` - Surface known issues, error logs, Sentry alerts
- `"general"` (default) - Balanced view of all context

### No User Input Required

Unlike **git-backup-specialist** (which requires session work summary), **get-up-to-speed** requires NO user input. It autonomously discovers and analyzes all necessary information.

---

## Agent Outputs

### Guaranteed Outputs

The agent ALWAYS produces the following outputs:

#### 1. Startup Summary Report (9 Sections)

**Format**: Markdown with emoji section headers

```markdown
# 🚀 Session Startup Summary
*Generated: [timestamp]*
*Source: [handoff filename]*

## 📍 Where You Left Off
**Last Session**: [Date] - [Topic from filename]
**Status**: [✅/⏳/⚠️/❌ status badge]
**Key Achievement**: [one sentence from Session Overview]
**Last Commit**: [hash] - [commit message]

## ⚡ Quick Start
**Working Directory**: [absolute path]
**Current Branch**: [branch name]
**Environment**: [staging/production/local]
**Uncommitted Changes**: [Yes/No] ([count] files if yes)

## 🎯 START HERE (Top 3-5 Actions)
1. [Action from IMMEDIATE ACTION section]
2. [Action #2]
3. [Action #3]
4. [Action #4 if applicable]
5. [Action #5 if applicable]

## 🏗️ System Status
**Frontend**: [URL] - [✅/⏳/⚠️/❌ status]
**Backend**: [URL] - [✅/⏳/⚠️/❌ status]
**Database**: [project name] - [status with details]
**Monitoring**: [Sentry/other] - [alert count or OK]

## ⚠️ Known Issues & Blockers
- [Issue 1 with severity indicator]
- [Issue 2 with severity indicator]
*(Shows "None - all systems operational" if 0 issues)*

## 📋 Can I...?
- **Deploy immediately?** [YES/NO - reason from Quick Status Check]
- **Run tests?** [YES/NO - what to verify]
- **Make changes safely?** [YES/NO - what's safe to modify]
- **[Custom check from handoff]** [YES/NO - context]

## 📞 Quick Reference
**Staging Environment**: [URL]
**Production Environment**: [URL]
**Sentry Dashboard**: [URL]
**Supabase Dashboard**: [URL]
**VPS SSH**: [command]

**Key Files Modified Recently**:
- [file 1 with absolute path] - [brief description]
- [file 2 with absolute path] - [brief description]
- [file 3 with absolute path] - [brief description]

**Recent Session Topics** (last 3):
1. [Date] - [Topic] - [✅/⏳/⚠️ Status]
2. [Date] - [Topic] - [✅/⏳/⚠️ Status]
3. [Date] - [Topic] - [✅/⏳/⚠️ Status]

## 🔧 Common Commands (Copy-Paste Ready)
```bash
# [Purpose from handoff/DEV_HANDOFF]
[command]

# [Purpose #2]
[command]

# [Purpose #3]
[command]
```

## 💡 Context Notes
- [Important reminder from DEV_HANDOFF.md]
- [MCP server configuration status]
- [Technology stack key points]
- [Environment variable notes (names only, not values)]

---
**Full Details**: See `[absolute path to most recent handoff]`
**Project Documentation**: See `DEV_HANDOFF.md`
**Time to Read Full Context**: ~5-10 minutes (if needed)

**⚠️ Staleness Warning**: [Only shown if handoff >3 days old]
This handoff is [N] days old. Consider verifying system status before making changes.
```

#### 2. Links to Full Documentation
- Absolute path to most recent session handoff
- Absolute path to DEV_HANDOFF.md
- Absolute path to project-specific CLAUDE.md (if exists)

#### 3. Warnings (Conditional)
- **Stale Handoff Warning**: If most recent handoff >3 days old
- **Uncommitted Changes Warning**: If git status shows uncommitted work
- **Critical Blocker Alert**: If handoff indicates ❌ blocked status
- **Missing Handoff Warning**: If no SESSION_HANDOFF_*.md files found (fallback to DEV_HANDOFF.md only)

---

## Agent Workflow

### 5-Phase Execution Plan

Each phase is time-boxed with clear deliverables:

---

### Phase 1: Context Discovery (20 seconds)

**Objective**: Identify project location, most recent work, and current git state

**Steps**:
1. **Determine working directory**
   ```bash
   pwd  # or echo %CD% on Windows
   ```

2. **Find most recent session handoff**
   ```bash
   # Use Glob tool to find SESSION_HANDOFF_*.md files
   # Sort by filename (contains date: YYYYMMDD format)
   # Select most recent
   ```

3. **Check git status**
   ```bash
   git status
   git branch --show-current
   git log --oneline -5
   ```

4. **Detect environment indicators**
   - Look for .env files
   - Check handoff for "staging" vs "production" mentions
   - Note MCP configurations in .claude/

**Deliverables**:
- Most recent handoff file path
- Current git branch name
- Last 5 commit hashes and messages
- Count of uncommitted files (if any)
- Environment type (staging/production/local/unknown)

---

### Phase 2: Session Analysis (25 seconds)

**Objective**: Extract critical startup information from most recent handoff

**Steps**:
1. **Read most recent handoff file** (use Read tool)

2. **Extract key sections** using markdown header patterns:
   - `## 🎯 Session Overview` → Parse for:
     - Date (from filename or overview)
     - Topic/focus
     - Status badge (✅/⏳/⚠️/❌)
     - Key achievement (one sentence)
     - Git commit hashes

   - `## 📋 Quick Status Check` → Parse for:
     - "Can I [action]?" questions with YES/NO answers
     - What to test/verify

   - `## 🎯 IMMEDIATE ACTION` or `### START HERE` → Extract:
     - Numbered list of 3-5 immediate actions
     - Goal statement
     - Expected time/outcome

   - `## 📊 System Status` → Parse for:
     - Frontend URL and status indicator
     - Backend URL and status indicator
     - Database project name and state
     - Monitoring/Sentry status

   - `## ⚠️ Known Issues` or blockers → Extract:
     - List of known issues with severity
     - Blocked scenarios (if any)

   - `## 🚀 Next Steps` → Extract:
     - 🔥 Immediate priorities
     - ⚠️ Short term tasks
     - 📝 Medium term goals

3. **Handle missing sections gracefully**:
   - If section not found, use placeholder: "See full handoff for details"
   - Never fail if a section is missing (older handoffs may have different formats)

**Deliverables**:
- Session overview summary (date, topic, status, achievement)
- List of 3-5 immediate actions
- System status indicators
- Known issues list
- Quick Status Check answers
- Next steps (prioritized)

---

### Phase 3: Historical Context (15 seconds)

**Objective**: Load long-term project context and identify patterns

**Steps**:
1. **Read DEV_HANDOFF.md** (use Read tool with limit)
   - Parse "Quick Start" section (first 50-100 lines usually sufficient)
   - Extract key URLs (staging, production, dashboards)
   - Note common commands
   - Identify MCP server configurations

2. **Optional: Scan previous handoffs** (if `full_history: true`)
   - Find previous 2 handoffs using Glob
   - Extract only Session Overview sections (quick scan)
   - Note recurring issues or multi-session work

3. **Read project-specific CLAUDE.md** (if exists)
   - Extract startup instructions
   - Note any special agent configurations

**Deliverables**:
- Quick start commands from DEV_HANDOFF.md
- Key URLs (staging, production, Sentry, Supabase, VPS)
- Recent session topics (last 3 sessions)
- Recurring issues (if pattern detected)
- Technology stack summary

---

### Phase 4: Current State Verification (10 seconds)

**Objective**: Check for any changes since last handoff

**Steps**:
1. **Check for new files**
   ```bash
   git status --short
   ```
   - Count untracked files
   - Count modified files (staged vs unstaged)

2. **Identify uncommitted changes** (if `include_git_diff: true`)
   ```bash
   git diff --stat
   git diff --cached --stat
   ```

3. **Verify working directory matches project**
   - Compare current directory with expected path from DEV_HANDOFF.md
   - Warn if mismatch detected

4. **Check for configuration changes**
   - Note if .env files modified
   - Check if MCP configurations changed

**Deliverables**:
- Uncommitted changes status (YES/NO + count)
- List of modified files (if any)
- Configuration change warnings (if any)
- Working directory verification result

---

### Phase 5: Summary Generation (10 seconds)

**Objective**: Compile all findings into concise startup summary

**Steps**:
1. **Generate 9-section summary** following output format (see Agent Outputs section)

2. **Apply focus filter** (if focus parameter provided):
   - `"deployment"` → Emphasize system status, URLs, deployment readiness
   - `"testing"` → Highlight testing workflows, verification steps
   - `"development"` → Focus on file locations, code changes
   - `"debugging"` → Surface known issues, error logs prominently

3. **Add warnings** (conditional):
   - Stale handoff warning (if >3 days old)
   - Uncommitted changes warning (if present)
   - Critical blocker alert (if ❌ status found)

4. **Format with markdown and emojis** for readability

5. **Output to console** (primary) or write to file (optional)

**Deliverables**:
- Complete startup summary (markdown formatted)
- Links to full documentation
- Warnings and alerts (if applicable)

---

## Information Sources

### Priority 1: Critical (Always Read)

These sources are ALWAYS consulted by the agent:

#### 1. Most Recent Session Handoff
- **Pattern**: `SESSION_HANDOFF_*.md` (sorted by date in filename)
- **Location**: Project root directory
- **Sections Read**:
  - 🎯 Session Overview
  - 📋 Quick Status Check
  - 🎯 IMMEDIATE ACTION
  - 📊 System Status
  - ⚠️ Known Issues
  - 🚀 Next Steps
- **Time**: ~10-15 seconds

#### 2. Git Status
- **Commands**:
  ```bash
  git status
  git branch --show-current
  git log --oneline -5
  ```
- **Purpose**: Check for uncommitted changes, identify current branch, show recent commits
- **Time**: ~5 seconds

#### 3. DEV_HANDOFF.md
- **Location**: Project root directory
- **Sections Read**:
  - Quick Start (first section)
  - Environment URLs
  - Common Commands
  - MCP Configurations
- **Strategy**: Skim key sections (don't read entire file)
- **Time**: ~10 seconds

---

### Priority 2: Important (Conditionally Read)

These sources are read when `full_history: true` or when additional context is needed:

#### 4. Previous Session Handoffs (2-3 files)
- **Pattern**: `SESSION_HANDOFF_*.md` (sorted by date DESC, skip most recent)
- **Sections Read**: Only Session Overview (quick scan)
- **Purpose**: Pattern recognition (recurring issues, multi-session progress)
- **Time**: ~15-20 seconds

#### 5. Project-Specific CLAUDE.md
- **Location**: `webaudit_pro_app/CLAUDE.md`
- **Sections Read**: Startup instructions, agent configurations
- **Time**: ~5 seconds

---

### Priority 3: Quick Checks (Fast Commands)

These are quick git/filesystem checks:

#### 6. Current Working Directory
```bash
pwd  # or echo %CD%
```

#### 7. Uncommitted Changes Detail (if `include_git_diff: true`)
```bash
git diff --stat
git diff --cached --stat
```

#### 8. Environment Detection
- Check for `.env`, `.env.staging`, `.env.production` files
- Look for environment indicators in handoff content

---

## Quality Checklist

Before completing execution, the agent MUST verify:

### ✅ Completeness Checks
- [ ] Most recent session handoff found and parsed
- [ ] All 9 sections of startup summary populated (or graceful fallback)
- [ ] Git status checked (branch, commits, uncommitted changes)
- [ ] DEV_HANDOFF.md Quick Start section read
- [ ] Key URLs extracted (staging, production, dashboards)
- [ ] IMMEDIATE ACTION items extracted (3-5 actions)

### ✅ Accuracy Checks
- [ ] Handoff date/age calculated correctly
- [ ] Status indicators match handoff (✅/⏳/⚠️/❌)
- [ ] Commit hashes are valid and recent
- [ ] File paths are absolute and accurate
- [ ] Environment detection is correct (staging/production)

### ✅ Safety Checks
- [ ] **NO API keys, tokens, or passwords in summary**
- [ ] **NO database credentials or secrets exposed**
- [ ] **Only reference locations** (e.g., "See .env file for credentials")
- [ ] Sensitive URLs are appropriate for sharing (exclude auth tokens)

### ✅ Usability Checks
- [ ] Startup summary is concise (<200 lines for quick reading)
- [ ] Immediate actions are clear and actionable
- [ ] Commands are copy-paste ready
- [ ] Links to full documentation are correct
- [ ] Warnings are shown if critical issues present

### ✅ Format Checks
- [ ] Markdown syntax is correct (headers, lists, code blocks)
- [ ] Emojis render correctly in section headers
- [ ] Code blocks have language specified (```bash, ```markdown, etc.)
- [ ] Status indicators use correct symbols (✅⏳⚠️❌)

---

## Error Handling

### Common Issues and Solutions

#### Issue 1: No Session Handoff Found
**Symptom**: No `SESSION_HANDOFF_*.md` files in project directory

**Solution**:
1. Display warning: "No session handoffs found. This may be a new project or first session."
2. Fall back to DEV_HANDOFF.md only
3. Generate summary with sections:
   - 📍 Where You Left Off → "New session - no previous handoff"
   - ⚡ Quick Start → Extract from DEV_HANDOFF.md
   - 🎯 START HERE → "Read DEV_HANDOFF.md for project setup"
   - 📞 Quick Reference → Extract URLs and commands from DEV_HANDOFF.md
4. Skip sections requiring handoff data (System Status, Known Issues)

---

#### Issue 2: Handoff Format Variations
**Symptom**: Older handoff doesn't follow 9-section structure

**Solution**:
1. Use regex patterns to find sections (e.g., `## .*Session Overview`, `## .*IMMEDIATE ACTION`)
2. If section not found, use placeholder: "See full handoff for details"
3. Extract what's available, skip what's missing
4. Never fail due to missing sections

---

#### Issue 3: Multiple Projects in Workspace
**Symptom**: Multiple `SESSION_HANDOFF_*.md` files from different projects

**Solution**:
1. Filter by current working directory
2. Only consider handoffs in current project folder
3. If ambiguous, prefer handoffs with most recent date
4. Display warning: "Multiple projects detected. Using handoffs from [current directory]."

---

#### Issue 4: Stale Handoff (>3 Days Old)
**Symptom**: Most recent handoff is more than 3 days old

**Solution**:
1. Calculate age: `(today - handoff_date).days`
2. Add prominent warning in summary:
   ```markdown
   ⚠️ **Staleness Warning**
   This handoff is [N] days old. Consider verifying:
   - System status (frontend/backend/database)
   - Recent commits on GitHub
   - Sentry alerts for new issues
   - Deployment status
   ```
3. Still generate summary (don't fail)

---

#### Issue 5: Uncommitted Changes Present
**Symptom**: `git status` shows modified or untracked files

**Solution**:
1. Add warning in "Quick Start" section:
   ```markdown
   ⚠️ **Uncommitted Changes**: YES ([count] files)

   Files modified:
   - [file1]
   - [file2]
   - [file3]

   ⚠️ Recommendation: Review uncommitted changes before starting new work.
   Run: git status && git diff
   ```
2. Optionally show `git diff --stat` if `include_git_diff: true`

---

#### Issue 6: Git Not Available
**Symptom**: Git commands fail (not installed or not a git repo)

**Solution**:
1. Skip git-related sections
2. Display warning: "Git not available. Skipping version control checks."
3. Generate summary from handoff and DEV_HANDOFF.md only
4. Recommend: "Run 'git init' if this should be a git repository."

---

#### Issue 7: Permission Errors Reading Files
**Symptom**: Cannot read handoff or DEV_HANDOFF.md due to permissions

**Solution**:
1. Try alternative locations (parent directory, common project paths)
2. If still failing, display clear error:
   ```markdown
   ❌ Error: Cannot read session handoff files

   Attempted locations:
   - [path1]
   - [path2]

   Recommendation: Check file permissions or run from project root directory.
   ```
3. Generate minimal summary with git status only

---

#### Issue 8: Handoff Too Large (>1000 lines)
**Symptom**: Reading entire handoff is slow or exceeds limits

**Solution**:
1. Read only key sections (use Read tool with targeted line ranges if possible)
2. Extract sections by header:
   - Find line numbers for each `## ` header
   - Read only relevant sections
3. If extraction fails, skim first 500 lines and last 200 lines
4. Add note: "Large handoff detected. Showing key sections. See full file for details."

---

## Examples

### Example 1: Minimal Invocation (Recommended)

**User Request**:
```markdown
Get me up to speed on the project.
```

**Agent Execution**:
1. Auto-detects working directory: `C:\Users\Ntro\weblser\webaudit_pro_app`
2. Finds most recent handoff: `SESSION_HANDOFF_20251102_GIT_BACKUP_SPECIALIST.md`
3. Parses handoff (finds all 9 sections)
4. Checks git: Branch `main`, 2 commits ahead, no uncommitted changes
5. Skims DEV_HANDOFF.md (extracts staging URL, common commands)
6. Generates startup summary with all 9 sections
7. No warnings (handoff is fresh, no uncommitted changes)

**Output Time**: ~65 seconds

---

### Example 2: Enhanced Invocation with Full History

**User Request**:
```markdown
Get me up to speed with:
- full_history: true
- include_git_diff: true
- focus: "testing"
```

**Agent Execution**:
1. Auto-detects working directory
2. Finds most recent handoff + previous 2 handoffs
3. Parses all 3 handoffs (extracts Session Overview from each)
4. Identifies pattern: "Testing workflow" mentioned in last 2 sessions
5. Checks git with detailed diff: `git diff --stat` shows 3 modified test files
6. Reads DEV_HANDOFF.md + scans for testing sections
7. Generates startup summary with testing emphasis:
   - 🧪 Testing Workflow section prominently featured
   - Lists modified test files
   - Shows uncommitted test changes
8. Adds warning: "Uncommitted test files present. Review before new changes."

**Output Time**: ~90 seconds

---

### Example 3: First Session (No Handoff)

**User Request**:
```markdown
Get me up to speed on the project.
```

**Agent Execution**:
1. Auto-detects working directory
2. Finds NO `SESSION_HANDOFF_*.md` files
3. Falls back to DEV_HANDOFF.md only
4. Checks git: Branch `main`, clean working directory
5. Generates minimal startup summary:
   - 📍 Where You Left Off → "New session - no previous handoff found"
   - ⚡ Quick Start → Extracted from DEV_HANDOFF.md
   - 🎯 START HERE → "Read DEV_HANDOFF.md for project overview"
   - 📞 Quick Reference → URLs and commands from DEV_HANDOFF.md
6. Warning: "No session handoffs found. This may be first session."

**Output Time**: ~40 seconds

---

### Example 4: Stale Handoff with Blockers

**User Request**:
```markdown
Get me up to speed.
```

**Agent Execution**:
1. Finds handoff: `SESSION_HANDOFF_20251027_COMPLIANCE_DEBUG.md` (6 days old)
2. Parses handoff, extracts:
   - Status: ⚠️ BLOCKED
   - Known Issues: "JSON parsing error blocking production deployment"
   - IMMEDIATE ACTION: "Fix JSON schema validation before deploying"
3. Checks git: 15 commits since handoff, 2 uncommitted files
4. Generates startup summary with prominent warnings:
   ```markdown
   ⚠️ **Staleness Warning**: Handoff is 6 days old
   ⚠️ **Critical Blocker**: JSON parsing error blocks deployment
   ⚠️ **Uncommitted Changes**: 2 files modified
   ```
5. START HERE section emphasizes:
   - "FIRST: Verify if JSON parsing bug is resolved"
   - "Check recent commits for fix"
   - "Test compliance audit endpoint before new work"

**Output Time**: ~70 seconds

---

## Tool Requirements

The agent requires access to the following tools:

### Required Tools

1. **Glob**
   - **Purpose**: Find `SESSION_HANDOFF_*.md` files in project directory
   - **Pattern**: `SESSION_HANDOFF_*.md`
   - **Sort**: By filename (date embedded in filename: YYYYMMDD)

2. **Read**
   - **Purpose**: Parse session handoff files, DEV_HANDOFF.md, CLAUDE.md
   - **Strategy**: Read full file or targeted sections
   - **Fallback**: Use line limits if files are large

3. **Bash**
   - **Purpose**: Execute git commands
   - **Commands Used**:
     - `git status`
     - `git branch --show-current`
     - `git log --oneline -5`
     - `git diff --stat` (optional)
     - `git diff --cached --stat` (optional)
     - `pwd` or `echo %CD%` (working directory)

### Optional Tools

4. **Grep** (optional)
   - **Purpose**: Search for specific patterns in handoffs
   - **Use Case**: Extract specific sections quickly without reading full file

5. **TodoWrite** (optional)
   - **Purpose**: Track startup checklist or create task list from IMMEDIATE ACTION
   - **Use Case**: If user wants to convert startup summary into trackable todos

---

## Success Metrics

### How to Measure Agent Effectiveness

The agent is successful if:

#### 1. Speed Metrics
- [ ] **Total execution time <90 seconds** (target: ~80 seconds)
- [ ] Developer can resume work within **2 minutes** of invocation
- [ ] Context loading is **50% faster** than manually reading handoffs

#### 2. Completeness Metrics
- [ ] **All 9 sections** of startup summary are populated (or graceful fallback)
- [ ] **3-5 immediate actions** extracted from handoff
- [ ] **Key URLs** (staging, production, dashboards) are present
- [ ] **System status** indicators are accurate

#### 3. Usability Metrics
- [ ] Developer doesn't need to ask **"What was I working on?"**
- [ ] Developer doesn't need to search for **URLs or commands**
- [ ] Developer can **copy-paste commands** directly from summary
- [ ] Developer knows **what to do first** without hesitation

#### 4. Safety Metrics
- [ ] **Zero secrets exposed** in summary (API keys, passwords, tokens)
- [ ] **All file paths are accurate** (no broken links)
- [ ] **Warnings are surfaced** for stale handoffs or blockers

#### 5. Quality Metrics
- [ ] Summary is **concise** (<200 lines for quick reading)
- [ ] Actions are **actionable** (clear, specific, time-bound)
- [ ] Links to **full documentation** are provided for deep dives
- [ ] Markdown **renders correctly** with proper formatting

---

## Comparison with git-backup-specialist

Understanding how this agent complements its counterpart:

| Aspect | git-backup-specialist | get-up-to-speed |
|--------|----------------------|-----------------|
| **Timing** | End of session | Start of session |
| **Purpose** | Create backup & handoff docs | Load context rapidly |
| **Execution Time** | ~3 minutes | ~80 seconds |
| **Primary Tool** | Write (create files) | Read (parse files) |
| **User Input** | Required (session summary) | None (auto-detect) |
| **Output** | 2 commits + handoff file | Startup summary (console) |
| **Context Window Impact** | -50 to -100 lines (saves future context) | Minimal (efficient loading) |
| **Focus** | Documentation & backup | Context loading & action |
| **Error Handling** | Must succeed (backup critical) | Graceful fallback (read-only) |

### Workflow Loop

```
Session End
    ↓
git-backup-specialist
    ↓
Create handoff doc (9 sections)
    ↓
Commit and push to Git
    ↓
[Next Session Starts]
    ↓
get-up-to-speed
    ↓
Read handoff doc
    ↓
Extract key context
    ↓
Generate startup summary
    ↓
Developer resumes work (2 min to productivity)
```

---

## Notes for Agent Developers

### Key Design Decisions

1. **No User Input Required**: Unlike git-backup-specialist, this agent auto-detects everything. This reduces friction at session start.

2. **Read-Only Operations**: Agent never writes files or commits. It's safe to run multiple times without side effects.

3. **Graceful Degradation**: If handoff is missing or malformed, agent falls back to DEV_HANDOFF.md and git status. Never fails completely.

4. **Time-Boxed Phases**: Each phase has strict time limit to ensure fast execution. Total time must stay under 2 minutes.

5. **Focus on Actionability**: Every section in startup summary should answer "What should I do?" rather than just "What happened?"

6. **Security First**: Never expose secrets. Always reference locations (e.g., "See .env for API key") instead of printing values.

7. **Visual Hierarchy**: Use emojis, status indicators, and markdown formatting to enable quick scanning. Developer should find critical info in <30 seconds.

### Future Enhancements (V2)

Potential features for future versions:

- **Pattern Detection**: Analyze multiple handoffs to identify recurring issues or bottlenecks
- **Time Estimation**: Predict how long remaining tasks will take based on historical data
- **Automated Verification**: Run quick health checks (ping URLs, check Sentry) and update status indicators in real-time
- **Multi-Project Support**: Handle workspaces with multiple projects, generate consolidated summary
- **Integration with External Tools**: Fetch Sentry alerts, GitHub PR status, CI/CD pipeline status
- **Interactive Mode**: Allow developer to ask follow-up questions about specific sections
- **Knowledge Base Generation**: Build a searchable knowledge base from all session handoffs

---

## Invocation Examples for Testing

### Test 1: Basic Functionality
```markdown
Using Task tool with subagent_type="get-up-to-speed":

Get me up to speed on the project.
```

**Expected Output**:
- 9-section startup summary
- Most recent handoff parsed
- Git status checked
- No errors or warnings (assuming clean state)

---

### Test 2: With Full History
```markdown
Using Task tool with subagent_type="get-up-to-speed":

Get me up to speed with:
- full_history: true
- include_git_diff: true
```

**Expected Output**:
- Summary includes context from last 3 handoffs
- Git diff details shown for uncommitted changes
- Recent session topics section populated

---

### Test 3: Focus on Deployment
```markdown
Using Task tool with subagent_type="get-up-to-speed":

Get me up to speed with focus on deployment.
```

**Expected Output**:
- System Status section emphasized
- Deployment URLs prominently displayed
- Production readiness checks highlighted

---

### Test 4: First Session (No Handoff)
```markdown
Using Task tool with subagent_type="get-up-to-speed":

Get me up to speed. (In a project with no SESSION_HANDOFF_*.md files)
```

**Expected Output**:
- Warning: "No session handoffs found"
- Summary generated from DEV_HANDOFF.md only
- START HERE: "Read DEV_HANDOFF.md for project overview"

---

## Quality Assurance

Before marking this agent as "production-ready", verify:

### ✅ Agent Specification Complete
- [ ] All sections documented (Overview, Capabilities, Inputs, Outputs, Workflow, etc.)
- [ ] Examples provided for common scenarios
- [ ] Error handling documented for edge cases
- [ ] Tool requirements clearly listed

### ✅ Agent Tested
- [ ] Test 1: Basic functionality (minimal invocation)
- [ ] Test 2: Enhanced invocation (full_history, git_diff, focus)
- [ ] Test 3: First session (no handoff present)
- [ ] Test 4: Stale handoff (>3 days old)
- [ ] Test 5: Uncommitted changes present

### ✅ Integration Verified
- [ ] Works in webaudit_pro_app project
- [ ] Compatible with git-backup-specialist handoff format
- [ ] Parses all 9 handoff sections correctly
- [ ] Extracts DEV_HANDOFF.md data accurately

### ✅ Security Verified
- [ ] Never exposes API keys or tokens
- [ ] Never exposes database credentials
- [ ] Never exposes passwords or secrets
- [ ] Only references file locations for sensitive data

### ✅ Performance Verified
- [ ] Executes in <90 seconds (target: ~80 seconds)
- [ ] Handles large handoffs (>1000 lines) gracefully
- [ ] Doesn't exceed reasonable token usage
- [ ] Provides concise output (<200 lines)

---

## Appendix: Handoff Section Patterns

### Common Regex Patterns for Parsing

When parsing handoff documents, use these patterns to find sections:

```regex
## 🎯 Session Overview
→ Pattern: ^##\s*🎯\s*Session Overview

## 📋 Quick Status Check
→ Pattern: ^##\s*📋\s*Quick Status Check

## 🎯 IMMEDIATE ACTION
→ Pattern: ^##\s*🎯\s*IMMEDIATE ACTION

### START HERE
→ Pattern: ^###\s*START HERE

## 📊 System Status
→ Pattern: ^##\s*📊\s*System Status

## ⚠️ Known Issues
→ Pattern: ^##\s*⚠️\s*Known Issues

## 🚀 Next Steps
→ Pattern: ^##\s*🚀\s*Next Steps

## 📞 Quick Reference
→ Pattern: ^##\s*📞\s*Quick Reference

## ✨ Session Summary
→ Pattern: ^##\s*✨\s*Session Summary
```

### Status Indicator Symbols

- ✅ Success / Complete / Operational
- ⏳ In Progress / Pending
- ⚠️ Warning / Needs Attention
- ❌ Blocked / Failed / Critical Issue

---

**End of Specification**

**Version**: 1.0.0
**Created**: November 2, 2025
**Status**: ✅ Ready for Testing
**Next Step**: Test agent with current project and refine based on results
