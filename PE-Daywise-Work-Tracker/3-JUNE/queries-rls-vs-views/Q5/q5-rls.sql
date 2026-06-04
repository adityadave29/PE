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

-- Step 4: Create policy — only show customers from ASIA region
CREATE POLICY customer_rls_policy ON customer
USING (
    EXISTS (
        SELECT 1 FROM nation n
        JOIN region r ON n.n_regionkey = r.r_regionkey
        WHERE n.n_nationkey = customer.c_nationkey
        AND r.r_name = 'ASIA'
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON customer TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
SET ROLE alice;

-- Step 6: Run Q5
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    n_name,
    sum(l_extendedprice * (1 - l_discount)) as revenue
from
    customer,
    orders,
    lineitem,
    supplier,
    nation,
    region
where
    c_custkey = o_custkey
    and l_orderkey = o_orderkey
    and l_suppkey = s_suppkey
    and c_nationkey = s_nationkey
    and s_nationkey = n_nationkey
    and n_regionkey = r_regionkey
    and r_name = 'ASIA'
    and o_orderdate >= date '1995-01-01'
    and o_orderdate < date '1995-01-01' + interval '1' year
group by
    n_name
order by
    revenue desc;