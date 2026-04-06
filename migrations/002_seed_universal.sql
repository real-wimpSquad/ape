-- ============================================================================
-- Migration 002: Universal Seed Data
-- Core linguistic data for L1 Glyph translation (domain-agnostic)
-- ============================================================================

-- ============================================================================
-- SEMANTIC ROLES: Preposition → Role mappings
-- ============================================================================
INSERT INTO l1_semantic_roles (preposition, role) VALUES
    -- Path/Motion
    ('across', 'path'), ('through', 'path'), ('into', 'path'), ('onto', 'path'),
    ('over', 'path'), ('along', 'path'), ('around', 'path'),
    -- Location
    ('in', 'loc'), ('on', 'loc'), ('at', 'loc'), ('under', 'loc'),
    ('near', 'loc'), ('beside', 'loc'), ('within', 'loc'), ('between', 'loc'),
    -- Goal/Direction
    ('to', 'goal'), ('toward', 'goal'), ('towards', 'goal'),
    -- Source
    ('from', 'src'), ('out', 'src'),
    -- Instrument/Means
    ('with', 'with'), ('by', 'by'), ('using', 'using'), ('via', 'via'),
    -- Cause/Purpose
    ('because', 'cause'), ('due', 'cause'), ('for', 'for'),
    -- Temporal
    ('before', 'before'), ('after', 'after'), ('during', 'during'),
    ('until', 'until'), ('since', 'since'), ('when', 'when'),
    -- Complementizer
    ('that', 'that'), ('whether', 'whether'),
    -- Manner/Comparison
    ('like', 'like'), ('as', 'as'),
    -- Topic
    ('about', 'about'), ('regarding', 'about'), ('concerning', 'about'),
    -- Other
    ('of', 'of')
ON CONFLICT (preposition) DO NOTHING;

-- ============================================================================
-- VERB LEMMAS: Irregular verb forms → base form
-- ============================================================================
INSERT INTO l1_verb_lemmas (inflected, lemma) VALUES
    -- Be
    ('was', 'be'), ('were', 'be'), ('is', 'be'), ('are', 'be'), ('am', 'be'),
    ('been', 'be'), ('being', 'be'),
    -- Have
    ('had', 'have'), ('has', 'have'), ('having', 'have'),
    -- Do
    ('did', 'do'), ('does', 'do'), ('doing', 'do'), ('done', 'do'),
    -- Go
    ('went', 'go'), ('goes', 'go'), ('gone', 'go'), ('going', 'go'),
    -- Know
    ('knew', 'know'), ('known', 'know'), ('knows', 'know'), ('knowing', 'know'),
    -- Say
    ('said', 'say'), ('says', 'say'), ('saying', 'say'),
    -- Make
    ('made', 'make'), ('makes', 'make'), ('making', 'make'),
    -- Take
    ('took', 'take'), ('taken', 'take'), ('takes', 'take'), ('taking', 'take'),
    -- Send
    ('sent', 'send'), ('sends', 'send'), ('sending', 'send'),
    -- Find
    ('found', 'find'), ('finds', 'find'), ('finding', 'find'),
    -- Hold
    ('held', 'hold'), ('holds', 'hold'), ('holding', 'hold'),
    -- See
    ('saw', 'see'), ('sees', 'see'), ('seen', 'see'), ('seeing', 'see'),
    -- Think
    ('thought', 'think'), ('thinks', 'think'), ('thinking', 'think'),
    -- Run
    ('ran', 'run'), ('runs', 'run'), ('running', 'run'),
    -- Give
    ('gave', 'give'), ('gives', 'give'), ('given', 'give'), ('giving', 'give'),
    -- Get
    ('got', 'get'), ('gets', 'get'), ('gotten', 'get'), ('getting', 'get'),
    -- Come
    ('came', 'come'), ('comes', 'come'), ('coming', 'come'),
    -- Put
    ('put', 'put'), ('puts', 'put'), ('putting', 'put'),
    -- Set
    ('set', 'set'), ('sets', 'set'), ('setting', 'set'),
    -- Write
    ('wrote', 'write'), ('written', 'write'), ('writes', 'write'), ('writing', 'write'),
    -- Read
    ('read', 'read'), ('reads', 'read'), ('reading', 'read'),
    -- Show
    ('showed', 'show'), ('shown', 'show'), ('shows', 'show'), ('showing', 'show'),
    -- Tell
    ('told', 'tell'), ('tells', 'tell'), ('telling', 'tell'),
    -- Become
    ('became', 'become'), ('becomes', 'become'), ('becoming', 'become'),
    -- Leave
    ('left', 'leave'), ('leaves', 'leave'), ('leaving', 'leave'),
    -- Keep
    ('kept', 'keep'), ('keeps', 'keep'), ('keeping', 'keep'),
    -- Begin
    ('began', 'begin'), ('begun', 'begin'), ('begins', 'begin'), ('beginning', 'begin'),
    -- Bring
    ('brought', 'bring'), ('brings', 'bring'), ('bringing', 'bring'),
    -- Build
    ('built', 'build'), ('builds', 'build'), ('building', 'build'),
    -- Buy
    ('bought', 'buy'), ('buys', 'buy'), ('buying', 'buy'),
    -- Choose
    ('chose', 'choose'), ('chosen', 'choose'), ('chooses', 'choose'), ('choosing', 'choose'),
    -- Draw
    ('drew', 'draw'), ('drawn', 'draw'), ('draws', 'draw'), ('drawing', 'draw'),
    -- Drive
    ('drove', 'drive'), ('driven', 'drive'), ('drives', 'drive'), ('driving', 'drive'),
    -- Eat
    ('ate', 'eat'), ('eaten', 'eat'), ('eats', 'eat'), ('eating', 'eat'),
    -- Fall
    ('fell', 'fall'), ('fallen', 'fall'), ('falls', 'fall'), ('falling', 'fall'),
    -- Feel
    ('felt', 'feel'), ('feels', 'feel'), ('feeling', 'feel'),
    -- Grow
    ('grew', 'grow'), ('grown', 'grow'), ('grows', 'grow'), ('growing', 'grow'),
    -- Hear
    ('heard', 'hear'), ('hears', 'hear'), ('hearing', 'hear'),
    -- Lose
    ('lost', 'lose'), ('loses', 'lose'), ('losing', 'lose'),
    -- Meet
    ('met', 'meet'), ('meets', 'meet'), ('meeting', 'meet'),
    -- Pay
    ('paid', 'pay'), ('pays', 'pay'), ('paying', 'pay'),
    -- Rise
    ('rose', 'rise'), ('risen', 'rise'), ('rises', 'rise'), ('rising', 'rise'),
    -- Sell
    ('sold', 'sell'), ('sells', 'sell'), ('selling', 'sell'),
    -- Sit
    ('sat', 'sit'), ('sits', 'sit'), ('sitting', 'sit'),
    -- Speak
    ('spoke', 'speak'), ('spoken', 'speak'), ('speaks', 'speak'), ('speaking', 'speak'),
    -- Spend
    ('spent', 'spend'), ('spends', 'spend'), ('spending', 'spend'),
    -- Stand
    ('stood', 'stand'), ('stands', 'stand'), ('standing', 'stand'),
    -- Teach
    ('taught', 'teach'), ('teaches', 'teach'), ('teaching', 'teach'),
    -- Understand
    ('understood', 'understand'), ('understands', 'understand'), ('understanding', 'understand'),
    -- Win
    ('won', 'win'), ('wins', 'win'), ('winning', 'win'),
    -- Wear
    ('wore', 'wear'), ('worn', 'wear'), ('wears', 'wear'), ('wearing', 'wear'),
    -- Break
    ('broke', 'break'), ('broken', 'break'), ('breaks', 'break'), ('breaking', 'break'),
    -- Catch
    ('caught', 'catch'), ('catches', 'catch'), ('catching', 'catch'),
    -- Cut
    ('cut', 'cut'), ('cuts', 'cut'), ('cutting', 'cut'),
    -- Fight
    ('fought', 'fight'), ('fights', 'fight'), ('fighting', 'fight'),
    -- Forget
    ('forgot', 'forget'), ('forgotten', 'forget'), ('forgets', 'forget'), ('forgetting', 'forget'),
    -- Hang
    ('hung', 'hang'), ('hangs', 'hang'), ('hanging', 'hang'),
    -- Hide
    ('hid', 'hide'), ('hidden', 'hide'), ('hides', 'hide'), ('hiding', 'hide'),
    -- Hit
    ('hit', 'hit'), ('hits', 'hit'), ('hitting', 'hit'),
    -- Hurt
    ('hurt', 'hurt'), ('hurts', 'hurt'), ('hurting', 'hurt'),
    -- Lay
    ('laid', 'lay'), ('lays', 'lay'), ('laying', 'lay'),
    -- Lead
    ('led', 'lead'), ('leads', 'lead'), ('leading', 'lead'),
    -- Lend
    ('lent', 'lend'), ('lends', 'lend'), ('lending', 'lend'),
    -- Lie (recline)
    ('lay', 'lie'), ('lain', 'lie'), ('lies', 'lie'), ('lying', 'lie'),
    -- Light
    ('lit', 'light'), ('lights', 'light'), ('lighting', 'light'),
    -- Mean
    ('meant', 'mean'), ('means', 'mean'), ('meaning', 'mean'),
    -- Ride
    ('rode', 'ride'), ('ridden', 'ride'), ('rides', 'ride'), ('riding', 'ride'),
    -- Ring
    ('rang', 'ring'), ('rung', 'ring'), ('rings', 'ring'), ('ringing', 'ring'),
    -- Seek
    ('sought', 'seek'), ('seeks', 'seek'), ('seeking', 'seek'),
    -- Shake
    ('shook', 'shake'), ('shaken', 'shake'), ('shakes', 'shake'), ('shaking', 'shake'),
    -- Shine
    ('shone', 'shine'), ('shines', 'shine'), ('shining', 'shine'),
    -- Shoot
    ('shot', 'shoot'), ('shoots', 'shoot'), ('shooting', 'shoot'),
    -- Shut
    ('shut', 'shut'), ('shuts', 'shut'), ('shutting', 'shut'),
    -- Sing
    ('sang', 'sing'), ('sung', 'sing'), ('sings', 'sing'), ('singing', 'sing'),
    -- Sink
    ('sank', 'sink'), ('sunk', 'sink'), ('sinks', 'sink'), ('sinking', 'sink'),
    -- Sleep
    ('slept', 'sleep'), ('sleeps', 'sleep'), ('sleeping', 'sleep'),
    -- Slide
    ('slid', 'slide'), ('slides', 'slide'), ('sliding', 'slide'),
    -- Stick
    ('stuck', 'stick'), ('sticks', 'stick'), ('sticking', 'stick'),
    -- Strike
    ('struck', 'strike'), ('strikes', 'strike'), ('striking', 'strike'),
    -- Swear
    ('swore', 'swear'), ('sworn', 'swear'), ('swears', 'swear'), ('swearing', 'swear'),
    -- Swim
    ('swam', 'swim'), ('swum', 'swim'), ('swims', 'swim'), ('swimming', 'swim'),
    -- Swing
    ('swung', 'swing'), ('swings', 'swing'), ('swinging', 'swing'),
    -- Tear
    ('tore', 'tear'), ('torn', 'tear'), ('tears', 'tear'), ('tearing', 'tear'),
    -- Throw
    ('threw', 'throw'), ('thrown', 'throw'), ('throws', 'throw'), ('throwing', 'throw'),
    -- Wake
    ('woke', 'wake'), ('woken', 'wake'), ('wakes', 'wake'), ('waking', 'wake'),
    -- Withdraw
    ('withdrew', 'withdraw'), ('withdrawn', 'withdraw'), ('withdraws', 'withdraw'), ('withdrawing', 'withdraw')
ON CONFLICT (inflected) DO NOTHING;

-- ============================================================================
-- SCAFFOLDING: Words to strip from output
-- ============================================================================
INSERT INTO l1_scaffolding (word, category) VALUES
    -- Determiners
    ('the', 'determiner'), ('a', 'determiner'), ('an', 'determiner'),
    ('this', 'determiner'), ('these', 'determiner'), ('those', 'determiner'),
    ('that', 'determiner'),
    -- Hedges/Intensifiers
    ('very', 'hedge'), ('really', 'hedge'), ('quite', 'hedge'),
    ('rather', 'hedge'), ('just', 'hedge'), ('only', 'hedge'), ('merely', 'hedge'),
    ('somewhat', 'hedge'), ('fairly', 'hedge'), ('pretty', 'hedge'),
    ('extremely', 'hedge'), ('incredibly', 'hedge'), ('absolutely', 'hedge'),
    -- Quantifiers
    ('some', 'quantifier'), ('any', 'quantifier'), ('each', 'quantifier'),
    ('every', 'quantifier'), ('certain', 'quantifier'), ('several', 'quantifier'),
    ('many', 'quantifier'), ('few', 'quantifier'), ('much', 'quantifier'),
    -- Discourse markers
    ('also', 'discourse'), ('however', 'discourse'), ('therefore', 'discourse'),
    ('thus', 'discourse'), ('hence', 'discourse'), ('moreover', 'discourse'),
    ('furthermore', 'discourse'), ('nevertheless', 'discourse'), ('nonetheless', 'discourse'),
    ('accordingly', 'discourse'), ('consequently', 'discourse'),
    -- Auxiliaries (stripped when not main verb)
    ('been', 'auxiliary'),
    -- Fillers
    ('basically', 'filler'), ('essentially', 'filler'), ('actually', 'filler'),
    ('literally', 'filler'), ('simply', 'filler'), ('generally', 'filler'),
    ('typically', 'filler'), ('usually', 'filler'), ('normally', 'filler')
ON CONFLICT (word) DO NOTHING;

-- ============================================================================
-- L3 PROMPTS: Teaching prompts for L3 LLM layer
-- Model is configurable per-prompt. Update via:
--   UPDATE l3_prompts SET model='your-model' WHERE name='glyph_teacher';
-- ============================================================================
INSERT INTO l3_prompts (name, prompt_template, model, max_tokens, temperature)
VALUES (
    'glyph_teacher',
    'You are a Glyph translation teacher for APE, a knowledge graph notation system. Your task is to:
1. Analyze why the content could not be translated by L1 patterns or L2 exemplars
2. Translate the content to Glyph notation
3. Optionally suggest a new L1 pattern if the content type is common

Content type detected: {content_type}

L1 patterns tried (none matched well):
{l1_patterns}

L2 similar entries found (none had valid APE syntax):
{l2_matches}

{ape_notation_rules}

Content to translate:
{raw_content}

Respond in JSON format:
{
    "analysis": "Why L1/L2 failed...",
    "compressed": "the_translated→glyph_notation|here",
    "new_pattern": {
        "name": "pattern_name",
        "regex": "regex_pattern",
        "replacement": "replacement_string",
        "confidence": 0.85,
        "domain": "optional_domain"
    }
}

If no good pattern can be generalized, omit the new_pattern field.
The "compressed" field (containing Glyph notation) is required.',
    'claude-haiku-4',  -- LiteLLM alias, configure in litellm_config.yaml
    1000,
    0.3
)
ON CONFLICT (name) DO NOTHING;
