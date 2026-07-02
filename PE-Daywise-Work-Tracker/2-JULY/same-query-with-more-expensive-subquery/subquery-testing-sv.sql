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
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

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
GRANT SELECT ON lineitem TO alice;

-- ============================================================
-- Benchmark
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    s_name
FROM supplier
WHERE s_suppkey IN (
    SELECT
        ps_suppkey
    FROM
        partsupp_secure      -- use partsupp_secure for the secure view version
    WHERE
        ps_partkey IN (
            SELECT
                p_partkey
            FROM
                part
            WHERE
                p_size BETWEEN 10 AND 20
        )
        AND EXISTS (
            SELECT 1
            FROM lineitem
            WHERE
                l_partkey = ps_partkey
                AND l_suppkey = ps_suppkey
                AND l_shipdate >= DATE '1995-01-01'
        )
        AND EXISTS (
            SELECT 1
            FROM lineitem l2
            WHERE
                l2.l_partkey = ps_partkey
                AND l2.l_suppkey = ps_suppkey
                AND l2.l_discount > 0.04
        )
);