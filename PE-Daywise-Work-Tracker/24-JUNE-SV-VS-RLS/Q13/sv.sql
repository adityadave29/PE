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

DROP VIEW IF EXISTS customer_secure CASCADE;

-- ============================================================
-- STEP 4: Create secure view
-- ============================================================

CREATE VIEW customer_secure
WITH (security_barrier = true)
AS
SELECT c.*
FROM customer c
WHERE c.c_acctbal > 0
  AND EXISTS (
        SELECT 1
        FROM nation n,
             region r
        WHERE n.n_nationkey = c.c_nationkey
          AND n.n_regionkey = r.r_regionkey
          AND r.r_name IN ('EUROPE', 'AMERICA')
  );

-- ============================================================
-- STEP 5: Grants
-- ============================================================

GRANT SELECT ON customer_secure TO alice;

GRANT SELECT ON orders TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;

-- ============================================================
-- STEP 6: Run benchmark
-- ============================================================

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        c_count,
        c_orderdate,
        count(*) as custdist
from
        (
                select
                        c_custkey,
                        o_orderdate,
                        count(o_orderkey)
                from
                        customer_secure left outer join orders on
                                c_custkey = o_custkey
                                and o_comment not like '%special%requests%'
                group by
                        c_custkey,
                        o_orderdate
        ) as c_orders (c_custkey, c_count, c_orderdate)
group by
        c_count,
        c_orderdate
order by
        custdist desc,
        c_count desc;