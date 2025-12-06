-- AI Discoverability Audits Table
-- Migration: 20251206_ai_audits_table.sql
-- Created: 2025-12-06
-- Description: Adds table for AI Discoverability Audit results

-- =============================================================================
-- CREATE TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.ai_audits (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign key to users (multi-tenant isolation)
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,

    -- Website information
    url TEXT NOT NULL,
    website_name TEXT,

    -- Overall scores
    overall_score NUMERIC(5,2),  -- 0-100 weighted score
    llm_confidence_score INTEGER CHECK (llm_confidence_score >= 0 AND llm_confidence_score <= 100),

    -- Primary identity (one-sentence summary)
    primary_identity TEXT,

    -- Detailed scores per criterion (JSONB for flexibility)
    -- Structure: { "criterion_name": { "score": 7.5, "weight": 0.20, "observation": "...", "findings": [...], "recommendations": [...] } }
    scores JSONB,

    -- Key findings
    key_strengths JSONB,  -- Array of strings
    critical_blockers JSONB,  -- Array of strings

    -- Recommendations with ROI
    -- Structure: [{ "title": "...", "criterion": "...", "description": "...", "cost_of_implementation": "Low/Medium/High", "expected_improvement": "...", "roi_assessment": "High/Medium/Low", "timeline": "...", "priority": 1 }]
    recommendations JSONB,

    -- Implementation roadmap
    -- Structure: { "phases": [{ "name": "Quick Wins", "timeframe": "0-4 weeks", "tasks": [...], "expected_score_improvement": "...", "total_effort": "..." }], "total_improvement": "..." }
    implementation_roadmap JSONB,

    -- Predicted prompts the site can answer
    predicted_prompts JSONB,  -- Array of strings

    -- Optional live test results
    -- Structure: { "tests": [{ "llm_name": "...", "query": "...", "found": bool, "accuracy": "...", "snippet": "..." }], "overall_visibility_score": 0-100 }
    live_test_results JSONB,

    -- Config flag
    run_live_tests BOOLEAN DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Index for user-based queries (most common access pattern)
CREATE INDEX IF NOT EXISTS ai_audits_user_id_idx ON public.ai_audits(user_id);

-- Index for URL lookups
CREATE INDEX IF NOT EXISTS ai_audits_url_idx ON public.ai_audits(url);

-- Index for timestamp-based sorting
CREATE INDEX IF NOT EXISTS ai_audits_created_at_idx ON public.ai_audits(created_at DESC);

-- Composite index for user + timestamp (history queries)
CREATE INDEX IF NOT EXISTS ai_audits_user_created_idx ON public.ai_audits(user_id, created_at DESC);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

-- Enable RLS
ALTER TABLE public.ai_audits ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own AI audits
CREATE POLICY "Users can view their own AI audits"
    ON public.ai_audits
    FOR SELECT
    USING (user_id = auth.uid());

-- Policy: Users can insert their own AI audits
CREATE POLICY "Users can insert their own AI audits"
    ON public.ai_audits
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Policy: Users can update their own AI audits
CREATE POLICY "Users can update their own AI audits"
    ON public.ai_audits
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Policy: Users can delete their own AI audits
CREATE POLICY "Users can delete their own AI audits"
    ON public.ai_audits
    FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- TRIGGERS
-- =============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_ai_audits_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_audits_updated_at_trigger
    BEFORE UPDATE ON public.ai_audits
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_audits_updated_at();

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE public.ai_audits IS 'AI Discoverability Audit results - evaluates website visibility to LLMs';
COMMENT ON COLUMN public.ai_audits.overall_score IS 'Weighted average score (0-100) across 7 criteria';
COMMENT ON COLUMN public.ai_audits.llm_confidence_score IS 'Confidence level (0-100%) that LLMs can understand this site';
COMMENT ON COLUMN public.ai_audits.primary_identity IS 'One-sentence AI summary of what the site does';
COMMENT ON COLUMN public.ai_audits.scores IS 'Detailed scores per criterion with observations and recommendations';
COMMENT ON COLUMN public.ai_audits.critical_blockers IS 'Red flags like robots.txt blocking AI crawlers';
COMMENT ON COLUMN public.ai_audits.implementation_roadmap IS 'Phased improvement plan with Quick Wins, Strategic, Comprehensive phases';
COMMENT ON COLUMN public.ai_audits.predicted_prompts IS 'Example questions users might ask LLMs that this site could answer';
COMMENT ON COLUMN public.ai_audits.live_test_results IS 'Results from live LLM visibility tests (optional)';

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant access to authenticated users (subject to RLS)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.ai_audits TO authenticated;

-- Grant access to anon for potential public endpoints (still subject to RLS)
GRANT SELECT ON public.ai_audits TO anon;

-- Service role bypasses RLS for backend operations
GRANT ALL ON public.ai_audits TO service_role;
