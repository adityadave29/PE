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
-- STEP 3: Drop existing views
-- ============================================================

DROP VIEW IF EXISTS supplier_secure CASCADE;
DROP VIEW IF EXISTS lineitem_secure CASCADE;

-- ============================================================
-- STEP 4: Create equivalent supplier view (p2)
-- ============================================================

CREATE VIEW supplier_secure AS
SELECT *
FROM supplier
WHERE s_acctbal > 0
  AND EXISTS (
        SELECT 1
        FROM nation n,
             region r
        WHERE n.n_nationkey = supplier.s_nationkey
          AND n.n_regionkey = r.r_regionkey
          AND r.r_name = 'EUROPE'
  );

-- ============================================================
-- STEP 5: Create equivalent lineitem view (p3)
-- ============================================================

CREATE VIEW lineitem_secure AS
SELECT *
FROM lineitem
WHERE EXISTS (
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
      );

-- ============================================================
-- STEP 6: Grants
-- ============================================================

GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON lineitem_secure TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON region TO alice;

-- ============================================================
-- STEP 7: Run benchmark user
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        s_name,
        count(*) as numwait
from
        supplier_secure,
        lineitem_secure l1,
        orders,
        nation
where
        s_suppkey = l1.l_suppkey
        and o_orderkey = l1.l_orderkey
        and o_orderstatus = 'F'
        and l1.l_receiptdate > l1.l_commitdate
        and exists (
                select *
                from lineitem l2
                where l2.l_orderkey = l1.l_orderkey
                  and l2.l_suppkey <> l1.l_suppkey
        )
        and not exists (
                select *
                from lineitem l3
                where l3.l_orderkey = l1.l_orderkey
                  and l3.l_suppkey <> l1.l_suppkey
                  and l3.l_receiptdate > l3.l_commitdate
        )
        and s_nationkey = n_nationkey
        and n_name = 'ARGENTINA'
group by
        s_name
order by
        numwait desc,
        s_name;