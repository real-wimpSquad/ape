-- ============================================================================
-- Migration 001: Core Schema
-- L1/L2/L3 Teaching Loop Tables
-- ============================================================================

-- L1 Patterns: Heuristic regex rules (zero LLM cost)
CREATE TABLE IF NOT EXISTS l1_patterns (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    regex TEXT NOT NULL,
    replacement TEXT NOT NULL,
    confidence FLOAT DEFAULT 0.8,
    domain TEXT,                    -- domain identifier for pattern routing
    content_type TEXT,              -- optional content type filter
    priority INT DEFAULT 100,       -- lower = applied first
    created_by TEXT,                -- 'manual' or model ID (L3 attribution)
    times_applied INT DEFAULT 0,
    times_succeeded INT DEFAULT 0,  -- L1 result accepted (no L3 needed)
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_patterns_domain ON l1_patterns(domain) WHERE active;
CREATE INDEX IF NOT EXISTS idx_patterns_content_type ON l1_patterns(content_type) WHERE active;
CREATE INDEX IF NOT EXISTS idx_patterns_priority ON l1_patterns(priority) WHERE active;

-- L3 Prompts: Teaching LLM prompts (stored in DB for easy editing)
CREATE TABLE IF NOT EXISTS l3_prompts (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    prompt_template TEXT NOT NULL,
    model TEXT DEFAULT 'claude-haiku-4',  -- LiteLLM alias, configure in litellm_config.yaml
    max_tokens INT DEFAULT 1000,
    temperature FLOAT DEFAULT 0.3,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prompts_active ON l3_prompts(name) WHERE active;

-- L1 Semantic Roles: preposition → semantic role mapping
CREATE TABLE IF NOT EXISTS l1_semantic_roles (
    id SERIAL PRIMARY KEY,
    preposition TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL,
    domain TEXT,                     -- optional domain restriction
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_semantic_roles_active ON l1_semantic_roles(preposition) WHERE active;

-- L1 Verb Lemmas: irregular verb → base form
CREATE TABLE IF NOT EXISTS l1_verb_lemmas (
    id SERIAL PRIMARY KEY,
    inflected TEXT UNIQUE NOT NULL,
    lemma TEXT NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_verb_lemmas_active ON l1_verb_lemmas(inflected) WHERE active;

-- L1 Scaffolding: words to strip (determiners, hedges, etc.)
CREATE TABLE IF NOT EXISTS l1_scaffolding (
    id SERIAL PRIMARY KEY,
    word TEXT UNIQUE NOT NULL,
    category TEXT,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scaffolding_active ON l1_scaffolding(word) WHERE active;

-- Migration tracking
CREATE TABLE IF NOT EXISTS _migrations (
    id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    applied_at TIMESTAMP DEFAULT NOW()
);
