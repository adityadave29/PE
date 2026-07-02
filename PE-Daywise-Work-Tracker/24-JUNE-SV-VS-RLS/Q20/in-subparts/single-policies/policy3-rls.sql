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
ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

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
-- STEP 7: Grants
-- ============================================================
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON lineitem TO alice;

GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON part TO alice;

-- ============================================================
-- STEP 8: Indexes
-- (one-time cost; CREATE INDEX itself can take a while on
-- large tables, but only runs once, not per-query)
-- ============================================================

-- Q20 correlated subquery: lineitem WHERE l_partkey=.. AND l_suppkey=.. AND l_shipdate>=..
CREATE INDEX IF NOT EXISTS idx_lineitem_partkey_suppkey_shipdate
    ON lineitem (l_partkey, l_suppkey, l_shipdate);

-- lineitem RLS policy EXISTS check against orders
CREATE INDEX IF NOT EXISTS idx_lineitem_orderkey
    ON lineitem (l_orderkey);

CREATE INDEX IF NOT EXISTS idx_orders_orderkey_priority
    ON orders (o_orderkey, o_orderpriority);

-- partsupp filter + RLS join to supplier
CREATE INDEX IF NOT EXISTS idx_partsupp_partkey_suppkey_availqty
    ON partsupp (ps_partkey, ps_suppkey, ps_availqty);

CREATE INDEX IF NOT EXISTS idx_partsupp_suppkey
    ON partsupp (ps_suppkey);

-- supplier RLS join to nation/region
CREATE INDEX IF NOT EXISTS idx_supplier_nationkey
    ON supplier (s_nationkey);

CREATE INDEX IF NOT EXISTS idx_nation_regionkey
    ON nation (n_regionkey);

-- part name filter (LIKE '%ivory%' has a leading wildcard, so a
-- plain btree index on p_name won't help; trigram index will)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_part_name_trgm
    ON part USING gin (p_name gin_trgm_ops);

ANALYZE lineitem;
ANALYZE orders;
ANALYZE partsupp;
ANALYZE supplier;
ANALYZE nation;
ANALYZE region;
ANALYZE part;

-- ============================================================
-- STEP 9: Run benchmark
-- ============================================================
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        s_name,
        s_address
from
        supplier,
        nation
where
        s_suppkey in (
                select
                        ps_suppkey
                from
                        partsupp
                where
                        ps_partkey in (
                                select
                                        p_partkey
                                from
                                        part
                                where
                                        p_name like '%ivory%'
                        )
                        and ps_availqty > (
                                select
                                        0.5 * sum(l_quantity)
                                from
                                        lineitem
                                where
                                        l_partkey = ps_partkey
                                        and l_suppkey = ps_suppkey
                                        and l_shipdate >= date '1995-01-01'
                                        and l_shipdate < date '1995-01-01' + interval '1' year
                        )
        )
        and s_nationkey = n_nationkey
        and n_name = 'FRANCE'
order by
        s_name;

--  Planning Time: 15.555 ms
--  Execution Time: 304.085 ms