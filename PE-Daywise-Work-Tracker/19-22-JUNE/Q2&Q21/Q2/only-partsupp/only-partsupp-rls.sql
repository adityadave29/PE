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
-- STEP 2: Drop all user-created indexes (optional benchmark cleanup)
-- ============================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT indexname
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND indexname NOT LIKE '%_pkey'
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I', r.indexname);
    END LOOP;
END;
$$;

-- ============================================================
-- STEP 3: Disable RLS everywhere
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
-- STEP 4: Enable RLS only on partsupp
-- ============================================================

ALTER TABLE partsupp ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 5: Create partsupp policy
-- ============================================================

CREATE POLICY partsupp_rls_policy
ON partsupp
USING (
    ps_availqty > 100
    AND EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_suppkey = partsupp.ps_suppkey
          AND s.s_acctbal > 0
    )
);

-- ============================================================
-- STEP 6: Grant permissions
-- ============================================================

GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;

-- ============================================================
-- STEP 7: Run as benchmark user
-- ============================================================

SET ROLE alice;

-- ============================================================
-- STEP 8: TPC-H Q2
-- ============================================================

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        s_acctbal,
        s_name,
        n_name,
        p_partkey,
        p_mfgr,
        s_address,
        s_phone,
        s_comment
from
        part,
        supplier,
        partsupp,
        nation,
        region
where
        p_partkey = ps_partkey
        and s_suppkey = ps_suppkey
        and p_size = 15
        and p_type like '%BRASS'
        and s_nationkey = n_nationkey
        and n_regionkey = r_regionkey
        and r_name = 'EUROPE'
        and ps_supplycost = (
                select
                        min(ps_supplycost)
                from
                        partsupp,
                        supplier,
                        nation,
                        region
                where
                        p_partkey = ps_partkey
                        and s_suppkey = ps_suppkey
                        and s_nationkey = n_nationkey
                        and n_regionkey = r_regionkey
                        and r_name = 'EUROPE'
        )
order by
        s_acctbal desc,
        n_name,
        s_name,
        p_partkey
limit 100;
