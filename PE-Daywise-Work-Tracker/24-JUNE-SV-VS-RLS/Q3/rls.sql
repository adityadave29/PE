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
-- STEP 3: Enable RLS
-- ============================================================

ALTER TABLE customer ENABLE ROW LEVEL SECURITY;
ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 4: Customer policy (p1)
-- ============================================================

CREATE POLICY customer_rls_policy
ON customer
USING (
    c_acctbal > 0
    AND EXISTS (
        SELECT 1
        FROM nation n,
             region r
        WHERE n.n_nationkey = customer.c_nationkey
          AND n.n_regionkey = r.r_regionkey
          AND r.r_name IN ('EUROPE', 'AMERICA')
    )
);

-- ============================================================
-- STEP 5: Lineitem policy (p3)
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
-- STEP 6: Grants
-- ============================================================

GRANT SELECT ON customer TO alice;
GRANT SELECT ON lineitem TO alice;

GRANT SELECT ON orders TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;

-- ============================================================
-- STEP 7: Run benchmark
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        l_orderkey,
        sum(l_extendedprice * (1 - l_discount)) as revenue,
        o_orderdate,
        o_shippriority
from
        customer,
        orders,
        lineitem
where
        c_mktsegment = 'FURNITURE'
        and c_custkey = o_custkey
        and l_orderkey = o_orderkey
        and o_orderdate < date '1995-01-01'
        and l_shipdate > date '1995-01-01'
group by
        l_orderkey,
        o_orderdate,
        o_shippriority
order by
        revenue desc,
        o_orderdate;