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

-- Step 3: Enable RLS on customer
ALTER TABLE customer ENABLE ROW LEVEL SECURITY;

-- Step 4: Create policy — only show customers with acctbal > 0
CREATE POLICY customer_rls_policy ON customer
USING (
    EXISTS (
        SELECT 1 FROM nation n
        WHERE n.n_nationkey = customer.c_nationkey
        AND customer.c_acctbal > 0
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON customer TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 6: Run Q13
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    c_count, c_orderdate,
    count(*) as custdist
from
    (
        select
            c_custkey, o_orderdate,
            count(o_orderkey)
        from
            customer left outer join orders on
                c_custkey = o_custkey
                and o_comment not like '%special%requests%'
        group by
            c_custkey, o_orderdate
    ) as c_orders (c_custkey, c_count, c_orderdate)
group by
    c_count, c_orderdate
order by
    custdist desc,
    c_count desc;