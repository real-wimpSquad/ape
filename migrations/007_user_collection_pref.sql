-- Add collection preference to user_preferences
-- Table is created by ape-graph on startup; this migration is safe to re-run.
-- If the table doesn't exist yet, skip — ape-graph will create it with the column.

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ape_user_preferences') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_name = 'ape_user_preferences' AND column_name = 'collection'
        ) THEN
            ALTER TABLE ape_user_preferences ADD COLUMN collection TEXT;
            RAISE NOTICE 'Added collection column to ape_user_preferences';
        END IF;
    ELSE
        RAISE NOTICE 'ape_user_preferences does not exist yet — ape-graph will create it with the collection column';
    END IF;
END $$;
