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
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

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
GRANT SELECT ON lineitem TO alice;

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    s_name
FROM supplier
WHERE EXISTS (
    SELECT 1
    FROM partsupp
    WHERE
        ps_suppkey = supplier.s_suppkey
        AND ps_availqty > 100
        AND ps_supplycost > 500
        AND EXISTS (
            SELECT 1
            FROM part
            WHERE
                p_partkey = ps_partkey
                AND p_size BETWEEN 5 AND 35
        )
);