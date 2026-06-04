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
GRANT SELECT ON orders TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 6: Run Q12
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    l_shipmode,
    sum(case
        when o_orderpriority = '1-URGENT'
            or o_orderpriority = '2-HIGH'
            then 1
        else 0
    end) as high_line_count,
    sum(case
        when o_orderpriority <> '1-URGENT'
            and o_orderpriority <> '2-HIGH'
            then 1
        else 0
    end) as low_line_count
from
    orders,
    lineitem
where
    o_orderkey = l_orderkey
    and l_shipmode = 'SHIP'
    and l_commitdate < l_receiptdate
    and l_shipdate < l_commitdate
    and l_receiptdate >= date '1995-01-01'
    and l_receiptdate < date '1995-01-01' + interval '1' year
group by
    l_shipmode
order by
    l_shipmode;