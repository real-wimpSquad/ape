-- ============================================================================
-- Migration 005: Add semantic_class to verb lemmas
--
-- ROOT CAUSE: verb_lemma_table lacks semantic class annotation
--   → "refuted" (evidential) and "talked" (narrative) compress identically
--   → L1 has no salience signal → noise passes L1/L2 validation
--
-- Classes (VerbNet/FrameNet inspired):
--   evidential  - assert/evaluate truth (prove, refute, show, know)
--   causal      - express causation/transformation (cause, make, break, drive)
--   narrative   - communication/reporting (say, tell, speak, write)
--   stative     - state/being (be, have, hold, keep, sit)
--   performative - action without epistemic/causal weight (walk, run, eat, swim)
--
-- Salience: evidential+causal = HIGH | narrative+stative+performative = LOW
-- ============================================================================

-- Add column (nullable so existing rows don't break)
ALTER TABLE l1_verb_lemmas ADD COLUMN IF NOT EXISTS semantic_class TEXT;

-- Index for filtering by class
CREATE INDEX IF NOT EXISTS idx_verb_lemmas_class ON l1_verb_lemmas(semantic_class) WHERE active;

-- ============================================================================
-- Classify existing lemmas by base form
-- ============================================================================

-- EVIDENTIAL: verbs that assert, evaluate, or reveal truth claims
UPDATE l1_verb_lemmas SET semantic_class = 'evidential' WHERE lemma IN (
    'know', 'show', 'see', 'think', 'understand', 'find',
    'mean', 'feel', 'hear', 'teach', 'seek'
);

-- CAUSAL: verbs expressing causation, enablement, transformation
UPDATE l1_verb_lemmas SET semantic_class = 'causal' WHERE lemma IN (
    'make', 'give', 'bring', 'build', 'drive', 'lead',
    'break', 'strike', 'hit', 'hurt', 'grow', 'cut'
);

-- NARRATIVE: verbs of communication and reporting
UPDATE l1_verb_lemmas SET semantic_class = 'narrative' WHERE lemma IN (
    'say', 'tell', 'speak', 'write', 'read', 'sing', 'swear'
);

-- STATIVE: verbs expressing states of being
UPDATE l1_verb_lemmas SET semantic_class = 'stative' WHERE lemma IN (
    'be', 'have', 'hold', 'keep', 'sit', 'stand',
    'lie', 'hang', 'sleep', 'become'
);

-- PERFORMATIVE: action verbs without strong epistemic/causal content
-- (everything else - catch-all for remaining unclassified)
UPDATE l1_verb_lemmas SET semantic_class = 'performative'
WHERE semantic_class IS NULL;
