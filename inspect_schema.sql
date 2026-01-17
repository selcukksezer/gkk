DO $$
DECLARE
    r RECORD;
BEGIN
    RAISE NOTICE '--- LIST OF BASE TABLES IN PUBLIC SCHEMA ---';
    FOR r IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
    LOOP
        RAISE NOTICE 'Table: %', r.table_name;
    END LOOP;
    
    RAISE NOTICE '--- LIST OF VIEWS IN PUBLIC SCHEMA ---';
    FOR r IN SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'VIEW'
    LOOP
        RAISE NOTICE 'View: %', r.table_name;
    END LOOP;
END $$;
