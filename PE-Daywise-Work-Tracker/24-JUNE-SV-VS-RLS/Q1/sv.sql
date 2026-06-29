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
-- STEP 3: Create secure view
-- ============================================================

DROP VIEW IF EXISTS lineitem_secure;

CREATE VIEW lineitem_secure
WITH (security_barrier = true)
AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.o_orderkey = l.l_orderkey
      AND o.o_orderpriority IN ('1-URGENT', '2-HIGH')
)
AND EXISTS (
    SELECT 1
    FROM partsupp ps
    WHERE ps.ps_partkey = l.l_partkey
      AND ps.ps_suppkey = l.l_suppkey
      AND ps.ps_availqty > 0
);

-- ============================================================
-- STEP 4: Grants
-- ============================================================

GRANT SELECT ON lineitem_secure TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON partsupp TO alice;

-- ============================================================
-- STEP 5: Run benchmark user
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    l_returnflag,
    l_linestatus,
    sum(l_quantity) as sum_qty,
    sum(l_extendedprice) as sum_base_price,
    sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
    avg(l_quantity) as avg_qty,
    avg(l_extendedprice) as avg_price,
    avg(l_discount) as avg_disc,
    count(*) as count_order
from
    lineitem_secure
where
    l_shipdate <= date '1998-12-01' - interval '3' day
group by
    l_returnflag,
    l_linestatus
order by
    l_returnflag,
    l_linestatus;