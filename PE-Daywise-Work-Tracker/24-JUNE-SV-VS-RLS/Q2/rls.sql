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
-- STEP 3: Enable RLS on supplier and partsupp
-- ============================================================

ALTER TABLE supplier ENABLE ROW LEVEL SECURITY;
ALTER TABLE partsupp ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 4: Supplier policy (p2)
-- ============================================================

CREATE POLICY supplier_rls_policy
ON supplier
USING (
    s_acctbal > 0
    AND EXISTS (
        SELECT 1
        FROM nation n,
             region r
        WHERE n.n_nationkey = supplier.s_nationkey
          AND n.n_regionkey = r.r_regionkey
          AND r.r_name = 'EUROPE'
    )
);

-- ============================================================
-- STEP 5: Partsupp policy (p4)
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
-- STEP 6: Grants
-- ============================================================

GRANT SELECT ON supplier TO alice;
GRANT SELECT ON partsupp TO alice;

GRANT SELECT ON part TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;

-- ============================================================
-- STEP 7: Run benchmark user
-- ============================================================

SET ROLE alice;

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
                        and n_regionkey = r.r_regionkey
                        and r_name = 'EUROPE'
        )
order by
        s_acctbal desc,
        n_name,
        s_name,
        p_partkey
limit 100;