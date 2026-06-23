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
-- STEP 4: Create supplier_secure (equivalent of p2)
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
-- STEP 5: Create partsupp_secure (equivalent of p4)
-- ============================================================

CREATE VIEW partsupp_secure AS
SELECT ps.*
FROM partsupp ps
WHERE ps.ps_availqty > 100
  AND EXISTS (
        SELECT 1
        FROM supplier_secure s
        WHERE s.s_suppkey = ps.ps_suppkey
          AND s.s_acctbal > 0
  );

-- ============================================================
-- STEP 6: Grants
-- ============================================================

GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON partsupp_secure TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;

-- ============================================================
-- STEP 7: Run benchmark user
-- ============================================================

SET ROLE alice;

-- ============================================================
-- STEP 8: Q2 using secure views
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
        partsupp_secure,
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
                        partsupp_secure,
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