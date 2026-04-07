-- ============================================================================
-- Migration 003: PTAB Domain Patterns
-- Patent Trial and Appeal Board document preprocessing
-- ============================================================================

INSERT INTO l1_patterns (name, regex, replacement, confidence, domain, content_type, priority, created_by) VALUES
    -- === NOISE REMOVAL (priority 1-4, run first) ===
    -- Brackets in quotes (editorial marks)
    ('ptab_bracket_the', '\[the\]', '', 0.95, 'ptab', 'ptab', 1, 'manual'),
    ('ptab_bracket_a', '\[a\]', '', 0.95, 'ptab', 'ptab', 1, 'manual'),
    ('ptab_bracket_an', '\[an\]', '', 0.95, 'ptab', 'ptab', 1, 'manual'),
    -- Citation references
    ('ptab_citing', '\s*\([Cc]iting\s+[^)]+\)', '', 0.95, 'ptab', 'ptab', 2, 'manual'),
    ('ptab_see_paren', '\s*\([Ss]ee\s+[^)]+\)', '', 0.95, 'ptab', 'ptab', 2, 'manual'),
    ('ptab_id_at', '\bId\.\s+at\s+\d+[-–]?\d*', '', 0.95, 'ptab', 'ptab', 2, 'manual'),
    ('ptab_see_also_id', '\b[Ss]ee\s+also\s+id\.?', '', 0.95, 'ptab', 'ptab', 2, 'manual'),
    ('ptab_emphasis', '\bemphasis\s+added\b', '', 0.95, 'ptab', 'ptab', 2, 'manual'),
    ('ptab_emphasis_paren', '\s*\(emphasis\s+[^)]+\)', '', 0.95, 'ptab', 'ptab', 2, 'manual'),
    ('ptab_col_cite', ',\s*\d+:\d+[-–]?\d*', '', 0.95, 'ptab', 'ptab', 2, 'manual'),
    -- Rehearing abbreviations
    ('ptab_req_rehg', 'Req\.\s*Reh''g\s*\d*[-–]?\d*', 'REQ_REHEARING', 0.95, 'ptab', 'ptab', 3, 'manual'),
    ('ptab_reg_rehg', 'Reg\.\s*Reh''g\s*\d*[-–]?\d*', 'REQ_REHEARING', 0.95, 'ptab', 'ptab', 3, 'manual'),
    -- Possessives
    ('ptab_possessive', '(\w+)''s\b', '\1', 0.9, 'ptab', 'ptab', 4, 'manual'),
    -- Stray punctuation cleanup
    ('ptab_stray_quotes', '["\x27`]', '', 0.95, 'ptab', 'ptab', 4, 'manual'),
    ('ptab_stray_brackets', '[\[\]]', '', 0.95, 'ptab', 'ptab', 4, 'manual'),

    -- === CLAIMS NORMALIZATION (priority 5) ===
    ('ptab_claims_range', '[Cc]laims?\s+(\d+)\s*[-–]\s*(\d+)', 'CLAIMS_\1-\2', 0.95, 'ptab', 'ptab', 5, 'manual'),
    ('ptab_claim_single', '[Cc]laim\s+(\d+)(?!\s*[-–])', 'CLAIMS_\1', 0.95, 'ptab', 'ptab', 5, 'manual'),

    -- === STATUTE NORMALIZATION (priority 6) ===
    ('ptab_35usc', '35\s+U\.?S\.?C\.?\s*§?\s*(\d+)', '§35USC\1', 0.95, 'ptab', 'ptab', 6, 'manual'),
    ('ptab_37cfr', '37\s+C\.?F\.?R\.?\s*§?\s*([\d.]+)', '§37CFR\1', 0.95, 'ptab', 'ptab', 6, 'manual'),

    -- === ENTITY NORMALIZATION (priority 10) ===
    ('ptab_examiner', '\b[Tt]he\s+[Ee]xaminer\b', 'EXAMINER', 0.95, 'ptab', 'ptab', 10, 'manual'),
    ('ptab_board', '\b[Tt]he\s+[Bb]oard\b', 'BOARD', 0.95, 'ptab', 'ptab', 10, 'manual'),
    ('ptab_appellant', '\b[Aa]ppellant\b', 'APPELLANT', 0.95, 'ptab', 'ptab', 10, 'manual'),
    ('ptab_petitioner', '\b[Pp]etitioner\b', 'PETITIONER', 0.95, 'ptab', 'ptab', 10, 'manual'),
    ('ptab_patent_owner', '\b[Pp]atent\s+[Oo]wner\b', 'PATENT_OWNER', 0.95, 'ptab', 'ptab', 10, 'manual'),

    -- === COMPOUND TERMS (priority 15) ===
    ('ptab_prior_art', '\bprior\s+art\b', 'prior_art', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_abstract_idea', '\babstract\s+idea\b', 'abstract_idea', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_inventive_concept', '\binventive\s+concept\b', 'inventive_concept', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_directed_to', '\bdirected\s+to\b', 'directed_to', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_step_one', '\bstep\s+one\b', 'step_one', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_step_two', '\bstep\s+two\b', 'step_two', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_req_for_rehearing', '\brequest\s+for\s+rehearing\b', 'request_for_rehearing', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_new_ground', '\bnew\s+ground\s+of\s+rejection\b', 'new_ground_rejection', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_points_law', '\bpoints\s+of\s+law\s+or\s+fact\b', 'points_law_fact', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_claim_construction', '\bclaim\s+construction\b', 'claim_construction', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_burden_of_proof', '\bburden\s+of\s+proof\b', 'burden_of_proof', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_preponderance', '\bpreponderance\s+of\s+(?:the\s+)?evidence\b', 'preponderance_evidence', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_skilled_artisan', '\b(?:person|one)\s+(?:of\s+)?(?:ordinary\s+)?skill(?:ed)?\s+in\s+the\s+art\b', 'POSITA', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_hydro_coupling', '\bhydrodynamic\s+coupling\b', 'hydrodynamic_coupling', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_switch_coupling', '\bswitchable\s+coupling\b', 'switchable_coupling', 0.9, 'ptab', 'ptab', 15, 'manual'),
    ('ptab_drive_unit', '\bdrive\s+unit\b', 'drive_unit', 0.9, 'ptab', 'ptab', 15, 'manual')
ON CONFLICT (name) DO NOTHING;

-- Domain-specific verb lemmas
INSERT INTO l1_verb_lemmas (inflected, lemma) VALUES
    ('argued', 'argue'), ('argues', 'argue'), ('arguing', 'argue'),
    ('erred', 'err'), ('errs', 'err'),
    ('rejected', 'reject'), ('rejects', 'reject'), ('rejecting', 'reject'),
    ('affirmed', 'affirm'), ('affirms', 'affirm'), ('affirming', 'affirm'),
    ('reversed', 'reverse'), ('reverses', 'reverse'), ('reversing', 'reverse'),
    ('claimed', 'claim'), ('claims', 'claim'), ('claiming', 'claim'),
    ('asserted', 'assert'), ('asserts', 'assert'), ('asserting', 'assert'),
    ('constituted', 'constitute'), ('constitutes', 'constitute'),
    ('directed', 'direct'), ('directs', 'direct'), ('directing', 'direct'),
    ('recited', 'recite'), ('recites', 'recite'), ('reciting', 'recite'),
    ('disclosed', 'disclose'), ('discloses', 'disclose'),
    ('anticipated', 'anticipate'), ('anticipates', 'anticipate'),
    ('rendered', 'render'), ('renders', 'render'), ('rendering', 'render'),
    ('relied', 'rely'), ('relies', 'rely'), ('relying', 'rely'),
    ('alleged', 'allege'), ('alleges', 'allege'), ('alleging', 'allege'),
    ('contended', 'contend'), ('contends', 'contend'), ('contending', 'contend'),
    ('addressed', 'address'), ('addresses', 'address'), ('addressing', 'address'),
    ('acknowledged', 'acknowledge'), ('acknowledges', 'acknowledge')
ON CONFLICT (inflected) DO NOTHING;
