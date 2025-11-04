#!/usr/bin/env python3
"""
Emergency secret cleanup script - removes exposed API keys from markdown files
"""
import re
import os
from pathlib import Path

# Files with exposed secrets
FILES_TO_CLEAN = [
    "SESSION_HANDOFF_NOV3_VERSION_UPDATE_AND_TESTING.md",
    "SESSION_HANDOFF_NOV3_COMPLIANCE_AUDIT_FIX.md",
    "SESSION_HANDOFF_NOV3_FULL_APP_TESTING.md",
    ".claude/reports/SECURITY_AUDIT_2025-11-03_ENV_CONFIG.md",
    "SESSION_SUMMARY_OCT30_STAGING_FIXES.md",
    "SESSION_SUMMARY_COMPLIANCE_FEATURE.md",
    "INFRASTRUCTURE_DOCUMENTATION.md",
    "SESSION_HANDOFF_NOV01_SENTRY_MCP.md",
    "SECURITY_REMEDIATION_SUMMARY.md",
]

# Patterns to redact
PATTERNS = [
    # Anthropic API keys
    (r'ANTHROPIC_API_KEY=sk-ant-api03-[A-Za-z0-9_-]+', 'ANTHROPIC_API_KEY=[REDACTED]'),
    (r'sk-ant-api03-[A-Za-z0-9_-]{95,}', '[REDACTED-ANTHROPIC-KEY]'),

    # Supabase service role keys (JWT format)
    (r'SUPABASE_SERVICE_ROLE_KEY=eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
     'SUPABASE_SERVICE_ROLE_KEY=[REDACTED]'),
    (r'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+(?=\n|\s|$)',
     '[REDACTED-SUPABASE-JWT]'),
]

def clean_file(filepath):
    """Remove secrets from a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        changes = 0

        # Apply all redaction patterns
        for pattern, replacement in PATTERNS:
            new_content = re.sub(pattern, replacement, content)
            if new_content != content:
                matches = len(re.findall(pattern, content))
                changes += matches
                content = new_content

        # Only write if changes were made
        if content != original_content:
            # Create backup
            backup_path = f"{filepath}.backup-secret-cleanup"
            with open(backup_path, 'w', encoding='utf-8') as f:
                f.write(original_content)

            # Write cleaned content
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)

            print(f"OK {filepath}: {changes} secrets redacted (backup: {backup_path})")
            return changes
        else:
            print(f"SKIP {filepath}: No secrets found")
            return 0

    except Exception as e:
        print(f"ERROR {filepath}: {str(e)}")
        return 0

def main():
    base_dir = Path(__file__).parent
    total_redacted = 0

    print("SECRET CLEANUP TOOL")
    print("=" * 60)

    for filename in FILES_TO_CLEAN:
        filepath = base_dir / filename
        if filepath.exists():
            count = clean_file(filepath)
            total_redacted += count
        else:
            print(f"WARNING: {filename}: File not found")

    print("=" * 60)
    print(f"COMPLETE: {total_redacted} secrets redacted across {len(FILES_TO_CLEAN)} files")
    print("\nNEXT STEPS:")
    print("1. Generate new Anthropic API key at https://console.anthropic.com/settings/keys")
    print("2. Rotate Supabase service role keys (these are CRITICAL)")
    print("3. Update .env files with new keys")
    print("4. Add patterns to .gitignore or use git-secrets")
    print("5. Consider using git filter-repo to clean history")

if __name__ == "__main__":
    main()
