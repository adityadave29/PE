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

-- Step 3: Enable RLS on orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Step 4: Create policy — only show orders from customers with acctbal > 5000
CREATE POLICY orders_rls_policy ON orders
USING (
    EXISTS (
        SELECT 1 FROM customer c
        WHERE c.c_custkey = orders.o_custkey
        AND c.c_acctbal > 5000
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON orders TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON lineitem TO alice;
SET ROLE alice;

-- Step 6: Run Q4 with timing
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    o_orderpriority,
    count(*) as order_count
from
    orders
where
    o_orderdate >= date '1994-01-01'
    and o_orderdate < date '1994-01-01' + interval '3' month
    and exists (
        select
            *
        from
            lineitem
        where
            l_orderkey = o_orderkey
            and l_commitdate < l_receiptdate
    )
group by
    o_orderpriority
order by
    o_orderpriority;



-- Planning Time: 2.684 ms
-- Execution Time: 2579.793 ms