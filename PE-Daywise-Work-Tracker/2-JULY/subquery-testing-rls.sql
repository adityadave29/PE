-- ============================================================
-- STEP 1: Drop existing policies
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
-- Enable RLS
-- ============================================================

ALTER TABLE partsupp ENABLE ROW LEVEL SECURITY;

CREATE POLICY partsupp_rls_policy
ON partsupp
USING (
    ps_availqty > 100
);

-- ============================================================
-- Grants
-- ============================================================

GRANT SELECT ON supplier TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON part TO alice;

-- ============================================================
-- Indexes
-- ============================================================

-- CREATE INDEX IF NOT EXISTS idx_partsupp_partkey
-- ON partsupp(ps_partkey);

-- CREATE INDEX IF NOT EXISTS idx_partsupp_suppkey
-- ON partsupp(ps_suppkey);

-- CREATE INDEX IF NOT EXISTS idx_partsupp_availqty
-- ON partsupp(ps_availqty);

-- CREATE INDEX IF NOT EXISTS idx_part_size
-- ON part(p_size);

-- ANALYZE supplier;
-- ANALYZE partsupp;
-- ANALYZE part;

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
    FROM partsupp
    WHERE ps_partkey IN (
        SELECT p_partkey
        FROM part
        WHERE p_size = 15
    )
);