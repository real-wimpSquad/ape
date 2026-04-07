-- Migration 006: Drop deprecated grammar/chunking tables
-- These tables supported the old RegexpParser-based L1 approach.
-- L1 now uses a local 3B model with DB-backed prompt composition.
-- Grammar and chunk mapping functionality has been fully removed from code.

DROP TABLE IF EXISTS l1_grammars;
DROP TABLE IF EXISTS l1_chunk_mappings;
