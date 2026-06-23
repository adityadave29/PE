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
-- STEP 2: Drop all existing views
-- ============================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT viewname
        FROM pg_views
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format(
            'DROP VIEW IF EXISTS %I CASCADE',
            r.viewname
        );
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
-- STEP 4: Create supplier secure view
-- ============================================================

CREATE VIEW supplier_secure AS
SELECT s.*
FROM supplier s
WHERE s.s_acctbal > 0
  AND EXISTS (
        SELECT 1
        FROM nation n,
             region r
        WHERE n.n_nationkey = s.s_nationkey
          AND n.n_regionkey = r.r_regionkey
          AND r.r_name = 'EUROPE'
  );

-- ============================================================
-- STEP 5: Grant permissions
-- ============================================================

GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON partsupp TO alice;

-- ============================================================
-- STEP 6: Run as benchmark user
-- ============================================================

SET ROLE alice;

-- ============================================================
-- STEP 7: TPC-H Q2 using supplier_secure
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
        supplier_secure,
        partsupp,
        nation,
        region
where
        p_partkey = ps_partkey
        and s_suppkey = ps_suppkey
        and p_size = 15
        and p_type like '%BRASS'
        and s_nationkey = n_nationkey
        and n_regionkey = region.r_regionkey
        and region.r_name = 'EUROPE'
        and ps_supplycost = (
                select
                        min(ps_supplycost)
                from
                        partsupp,
                        supplier_secure,
                        nation,
                        region
                where
                        p_partkey = ps_partkey
                        and s_suppkey = ps_suppkey
                        and s_nationkey = n_nationkey
                        and n_regionkey = region.r_regionkey
                        and region.r_name = 'EUROPE'
        )
order by
        s_acctbal desc,
        n_name,
        s_name,
        p_partkey
limit 100;