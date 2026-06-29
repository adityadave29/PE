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
-- STEP 3: Drop old secure views
-- ============================================================

DROP VIEW IF EXISTS supplier_secure CASCADE;
DROP VIEW IF EXISTS partsupp_secure CASCADE;
DROP VIEW IF EXISTS lineitem_secure CASCADE;

-- ============================================================
-- STEP 4: Create secure views
-- ============================================================

CREATE VIEW supplier_secure
WITH (security_barrier = true)
AS
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

CREATE VIEW partsupp_secure
WITH (security_barrier = true)
AS
SELECT ps.*
FROM partsupp ps
WHERE ps.ps_availqty > 100
  AND EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_suppkey = ps.ps_suppkey
          AND s.s_acctbal > 0
  );

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
-- STEP 5: Grants
-- ============================================================

GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON partsupp_secure TO alice;
GRANT SELECT ON lineitem_secure TO alice;

GRANT SELECT ON orders TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;

-- ============================================================
-- STEP 6: Run benchmark
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        nation,
        o_year,
        sum(amount) as sum_profit
from
        (
                select
                        n_name as nation,
                        p_name,
                        extract(year from o_orderdate) as o_year,
                        l_extendedprice * (1 - l_discount)
                            - ps_supplycost * l_quantity as amount
                from
                        part,
                        supplier_secure,
                        lineitem_secure,
                        partsupp_secure,
                        orders,
                        nation
                where
                        s_suppkey = l_suppkey
                        and ps_suppkey = l_suppkey
                        and ps_partkey = l_partkey
                        and p_partkey = l_partkey
                        and o_orderkey = l_orderkey
                        and s_nationkey = n_nationkey
                        and p_name like 'co%'
        ) as profit
group by
        nation,
        o_year
order by
        nation,
        o_year desc;