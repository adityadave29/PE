-- ============================================================
-- STEP 1: Drop all existing RLS policies
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

-- ============================================================
-- STEP 2: Disable RLS everywhere
-- ============================================================
RESET ROLE;

ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE customer DISABLE ROW LEVEL SECURITY;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;
ALTER TABLE part DISABLE ROW LEVEL SECURITY;
ALTER TABLE partsupp DISABLE ROW LEVEL SECURITY;
ALTER TABLE nation DISABLE ROW LEVEL SECURITY;
ALTER TABLE region DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 3: Drop old secure views
-- ============================================================
DROP VIEW IF EXISTS supplier_secure CASCADE;
DROP VIEW IF EXISTS partsupp_secure CASCADE;
DROP VIEW IF EXISTS lineitem_secure CASCADE;

-- ============================================================
-- STEP 4: Create secure view
-- ============================================================

CREATE VIEW partsupp_secure
WITH (security_barrier = true)
AS
SELECT ps.*
FROM partsupp ps
WHERE ps.ps_availqty > 100
  AND EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_suppkey = ps.ps_suppkey
          AND s.s_acctbal > 0
  );

-- ============================================================
-- STEP 5: Grants
-- ============================================================
GRANT SELECT ON partsupp_secure TO alice;

GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON part TO alice;

-- ============================================================
-- STEP 6: Update statistics
-- ============================================================
ANALYZE lineitem;
ANALYZE orders;
ANALYZE partsupp;
ANALYZE supplier;
ANALYZE nation;
ANALYZE region;
ANALYZE part;

-- ============================================================
-- STEP 7: Run benchmark
-- ============================================================
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    s_name,
    s_address
FROM
    supplier,
    nation
WHERE
    s_suppkey IN (
        SELECT
            ps_suppkey
        FROM
            partsupp_secure
        WHERE
            ps_partkey IN (
                SELECT
                    p_partkey
                FROM
                    part
                WHERE
                    p_name LIKE '%ivory%'
            )
            AND ps_availqty > (
                SELECT
                    0.5 * SUM(l_quantity)
                FROM
                    lineitem
                WHERE
                    l_partkey = ps_partkey
                    AND l_suppkey = ps_suppkey
                    AND l_shipdate >= DATE '1995-01-01'
                    AND l_shipdate < DATE '1995-01-01' + INTERVAL '1' YEAR
            )
    )
    AND s_nationkey = n_nationkey
    AND n_name = 'FRANCE'
ORDER BY
    s_name;

-- Planning Time: 12.403 ms
-- Execution Time: 814.154 ms