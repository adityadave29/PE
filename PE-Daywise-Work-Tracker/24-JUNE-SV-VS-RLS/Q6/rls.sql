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
-- STEP 3: Enable RLS on lineitem
-- ============================================================

ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 4: Lineitem policy (p3)
-- ============================================================

CREATE POLICY lineitem_rls_policy
ON lineitem
USING (
    EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.o_orderkey = lineitem.l_orderkey
          AND o.o_orderpriority IN ('1-URGENT', '2-HIGH')
    )
    AND EXISTS (
        SELECT 1
        FROM partsupp ps
        WHERE ps.ps_partkey = lineitem.l_partkey
          AND ps.ps_suppkey = lineitem.l_suppkey
          AND ps.ps_availqty > 0
    )
);

-- ============================================================
-- STEP 5: Grants
-- ============================================================

GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON partsupp TO alice;

-- ============================================================
-- STEP 6: Run benchmark
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        sum(l_extendedprice * l_discount) as revenue
from
        lineitem
where
        l_shipdate >= date '1993-01-01'
        and l_shipdate < date '1994-03-01' + interval '1' year
        and l_discount between 0.06 - 0.01 and 0.06 + 0.01
        and l_quantity < 10;