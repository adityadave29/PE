-- Step 1: Drop all existing policies
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
    END LOOP;
END;
$$;

-- Step 2: Disable RLS on all tables
RESET ROLE;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE customer DISABLE ROW LEVEL SECURITY;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;
ALTER TABLE part DISABLE ROW LEVEL SECURITY;
ALTER TABLE partsupp DISABLE ROW LEVEL SECURITY;
ALTER TABLE nation DISABLE ROW LEVEL SECURITY;
ALTER TABLE region DISABLE ROW LEVEL SECURITY;

-- Step 3: Enable RLS on lineitem
ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

-- Step 4: Create policy — only show lineitems from suppliers with acctbal > 1000
CREATE POLICY lineitem_rls_policy ON lineitem
USING (
    EXISTS (
        SELECT 1 FROM supplier s
        WHERE s.s_suppkey = lineitem.l_suppkey
        AND s.s_acctbal > 1000
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 6: Run Q17
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select sum(l_extendedprice) / 7.0 as avg_yearly
from
    lineitem,
    part
where
    p_partkey = l_partkey
    and p_brand = 'Brand#53'
    and p_container = 'MED BAG'
    and l_quantity < (
        select
            0.7 * avg(l_quantity)
        from
            lineitem
        where
            l_partkey = p_partkey
    );