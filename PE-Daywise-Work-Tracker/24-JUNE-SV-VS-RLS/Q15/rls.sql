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

ALTER TABLE supplier ENABLE ROW LEVEL SECURITY;
ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

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

GRANT SELECT ON supplier TO alice;
GRANT SELECT ON lineitem TO alice;

GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON partsupp TO alice;

-- ============================================================
-- STEP 7: Run benchmark
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
with revenue(supplier_no, total_revenue) as
(
    select
            l_suppkey,
            sum(l_extendedprice * (1 - l_discount))
    from
            lineitem
    where
            l_shipdate >= date '1995-01-01'
            and l_shipdate < date '1995-01-01' + interval '3' month
    group by
            l_suppkey
)
select
        s_suppkey,
        s_name,
        s_address,
        s_phone,
        total_revenue
from
        supplier,
        revenue
where
        s_suppkey = supplier_no
        and total_revenue = (
                select
                        max(total_revenue)
                from
                        revenue
        )
order by
        s_suppkey;