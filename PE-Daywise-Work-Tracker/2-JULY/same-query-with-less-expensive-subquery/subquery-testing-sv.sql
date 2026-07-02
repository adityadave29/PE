-- ============================================================
-- STEP 1: Drop policies
-- ============================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT policyname, tablename
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format(
            'DROP POLICY IF EXISTS %I ON %I',
            r.policyname,
            r.tablename
        );
    END LOOP;
END;
$$;

RESET ROLE;

ALTER TABLE partsupp DISABLE ROW LEVEL SECURITY;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;
ALTER TABLE part DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- Drop/Create Secure View
-- ============================================================

DROP VIEW IF EXISTS partsupp_secure;

CREATE VIEW partsupp_secure
WITH (security_barrier = true)
AS
SELECT *
FROM partsupp
WHERE ps_availqty > 100;

-- ============================================================
-- Grants
-- ============================================================

GRANT SELECT ON supplier TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON partsupp_secure TO alice;

-- ============================================================
-- Benchmark
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    s_name
FROM supplier
WHERE s_suppkey IN (
    SELECT ps_suppkey
    FROM partsupp_secure
    WHERE ps_partkey IN (
        SELECT p_partkey
        FROM part
        WHERE p_partkey <= 10
    )
);