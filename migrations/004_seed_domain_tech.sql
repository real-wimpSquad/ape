-- ============================================================================
-- Migration 004: Tech Domain Patterns
-- API docs, error messages, changelogs, technical documentation
-- ============================================================================

INSERT INTO l1_patterns (name, regex, replacement, confidence, domain, content_type, priority, created_by) VALUES
    -- === HTTP VERBS (priority 5) ===
    ('tech_http_verb', '\b(GET|POST|PUT|DELETE|PATCH)\s+(/\S+)', '\1:\2', 0.95, 'tech', NULL, 5, 'manual'),

    -- === COMPOUND TERMS (priority 15) ===
    ('tech_auth_module', '\bauthentication\s+module\b', 'auth_module', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_db_connection', '\bdatabase\s+connection\b', 'db_connection', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_api_endpoint', '\bAPI\s+endpoint\b', 'api_endpoint', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_error_handling', '\berror\s+handling\b', 'error_handling', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_config_file', '\bconfiguration\s+file\b', 'config_file', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_env_var', '\benvironment\s+variable\b', 'env_var', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_dep_inject', '\bdependency\s+injection\b', 'dep_injection', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_rate_limit', '\brate\s+limit(?:ing)?\b', 'rate_limit', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_load_balance', '\bload\s+balanc(?:ing|er)\b', 'load_balance', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_circuit_break', '\bcircuit\s+breaker\b', 'circuit_breaker', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_service_mesh', '\bservice\s+mesh\b', 'service_mesh', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_message_queue', '\bmessage\s+queue\b', 'message_queue', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_event_loop', '\bevent\s+loop\b', 'event_loop', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_connection_pool', '\bconnection\s+pool(?:ing)?\b', 'conn_pool', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_thread_safe', '\bthread[- ]safe\b', 'thread_safe', 0.9, 'tech', NULL, 15, 'manual'),
    ('tech_async_await', '\basync(?:hronous)?\s+(?:and\s+)?await\b', 'async_await', 0.9, 'tech', NULL, 15, 'manual')
ON CONFLICT (name) DO NOTHING;

-- Changelog patterns
INSERT INTO l1_patterns (name, regex, replacement, confidence, domain, content_type, priority, created_by) VALUES
    ('changelog_deprecated', '[Dd]eprecated\s+[`"'']?(\w+)[`"'']?\s+in\s+favor\s+of\s+[`"'']?(\w+)[`"'']?', '\1→deprecated:\2', 0.9, 'changelog', 'changelog', 10, 'manual'),
    ('changelog_added', '[Aa]dded\s+(?:support\s+for\s+)?[`"'']?(\w+)[`"'']?', '+\1', 0.85, 'changelog', 'changelog', 20, 'manual'),
    ('changelog_removed', '[Rr]emoved\s+[`"'']?(\w+)[`"'']?', '-\1', 0.85, 'changelog', 'changelog', 30, 'manual'),
    ('changelog_fixed', '[Ff]ixed\s+(?:bug\s+in\s+)?[`"'']?(\w+)[`"'']?', '~\1', 0.85, 'changelog', 'changelog', 40, 'manual')
ON CONFLICT (name) DO NOTHING;

-- API documentation patterns
INSERT INTO l1_patterns (name, regex, replacement, confidence, domain, content_type, priority, created_by) VALUES
    ('api_params', '[Pp]arameters?:\s*\n((?:\s*[-\*]\s*`?\w+`?\s*\([^)]+\)[^\n]*\n?)+)', 'params:\1', 0.8, 'api', 'api_spec', 50, 'manual'),
    ('api_returns', '[Rr]eturns?:\s*([^\n]+)', 'returns:\1', 0.8, 'api', 'api_spec', 60, 'manual'),
    ('api_endpoint', '[Ee]ndpoint:\s*`?([A-Z]+)\s+(/[^\s`]+)`?', '\1\2', 0.85, 'api', 'api_spec', 70, 'manual')
ON CONFLICT (name) DO NOTHING;

-- Error message patterns
INSERT INTO l1_patterns (name, regex, replacement, confidence, domain, content_type, priority, created_by) VALUES
    ('error_cause', '[Ee]rror[:\s]+[`"'']?(\w+)[`"'']?[:\s]+[Cc]aused\s+by\s+[`"'']?(\w+)[`"'']?', '\1→caused_by:\2', 0.9, 'error', 'error_message', 80, 'manual'),
    ('error_exception', '[Ee]xception[:\s]+[`"'']?(\w+)[`"'']?[:\s]+(.+)', '\1_exception:\2', 0.85, 'error', 'error_message', 90, 'manual')
ON CONFLICT (name) DO NOTHING;

-- Relationship patterns (universal)
INSERT INTO l1_patterns (name, regex, replacement, confidence, domain, content_type, priority, created_by) VALUES
    ('rel_instance_of', '([A-Z][a-zA-Z]+(?:[A-Z][a-zA-Z]+)*|\w+_\w+)\s+(?:is\s+)?(?:a\s+)?(?:type|kind|instance)\s+of\s+([A-Z][a-zA-Z]+|\w+)', '\1→instance_of:\2', 0.85, NULL, NULL, 100, 'manual'),
    ('rel_requires', '([A-Z][a-zA-Z]+(?:[A-Z][a-zA-Z]+)*|\w+_\w+)\s+(?:requires?|needs?|depends?\s+on)\s+([A-Z][a-zA-Z]+|\w+_\w+)', '\1→requires:\2', 0.85, NULL, NULL, 110, 'manual'),
    ('rel_uses', '([A-Z][a-zA-Z]+(?:[A-Z][a-zA-Z]+)*|\w+_\w+)\s+(?:uses?|utilizes?)\s+([A-Z][a-zA-Z]+|\w+_\w+)', '\1→uses:\2', 0.8, NULL, NULL, 120, 'manual')
ON CONFLICT (name) DO NOTHING;

-- Tech-specific verb lemmas
INSERT INTO l1_verb_lemmas (inflected, lemma) VALUES
    ('processed', 'process'), ('processes', 'process'), ('processing', 'process'),
    ('handled', 'handle'), ('handles', 'handle'), ('handling', 'handle'),
    ('occurred', 'occur'), ('occurs', 'occur'), ('occurring', 'occur'),
    ('caused', 'cause'), ('causes', 'cause'), ('causing', 'cause'),
    ('failed', 'fail'), ('fails', 'fail'), ('failing', 'fail'),
    ('returned', 'return'), ('returns', 'return'), ('returning', 'return'),
    ('created', 'create'), ('creates', 'create'), ('creating', 'create'),
    ('updated', 'update'), ('updates', 'update'), ('updating', 'update'),
    ('deleted', 'delete'), ('deletes', 'delete'), ('deleting', 'delete'),
    ('connected', 'connect'), ('connects', 'connect'), ('connecting', 'connect'),
    ('validated', 'validate'), ('validates', 'validate'), ('validating', 'validate'),
    ('initialized', 'initialize'), ('initializes', 'initialize'), ('initializing', 'initialize'),
    ('configured', 'configure'), ('configures', 'configure'), ('configuring', 'configure'),
    ('deployed', 'deploy'), ('deploys', 'deploy'), ('deploying', 'deploy'),
    ('executed', 'execute'), ('executes', 'execute'), ('executing', 'execute'),
    ('invoked', 'invoke'), ('invokes', 'invoke'), ('invoking', 'invoke'),
    ('triggered', 'trigger'), ('triggers', 'trigger'), ('triggering', 'trigger'),
    ('emitted', 'emit'), ('emits', 'emit'), ('emitting', 'emit'),
    ('subscribed', 'subscribe'), ('subscribes', 'subscribe'), ('subscribing', 'subscribe'),
    ('published', 'publish'), ('publishes', 'publish'), ('publishing', 'publish'),
    ('queued', 'queue'), ('queues', 'queue'), ('queueing', 'queue'),
    ('cached', 'cache'), ('caches', 'cache'), ('caching', 'cache'),
    ('serialized', 'serialize'), ('serializes', 'serialize'), ('serializing', 'serialize'),
    ('deserialized', 'deserialize'), ('deserializes', 'deserialize'), ('deserializing', 'deserialize'),
    ('parsed', 'parse'), ('parses', 'parse'), ('parsing', 'parse'),
    ('rendered', 'render'), ('renders', 'render'), ('rendering', 'render'),
    ('fetched', 'fetch'), ('fetches', 'fetch'), ('fetching', 'fetch'),
    ('polled', 'poll'), ('polls', 'poll'), ('polling', 'poll')
ON CONFLICT (inflected) DO NOTHING;
