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

-- Step 4: Create policy — only show orders from customers in ASIA region
CREATE POLICY orders_rls_policy ON orders
USING (
    EXISTS (
        SELECT 1 FROM customer c
        JOIN nation n1 ON c.c_nationkey = n1.n_nationkey
        JOIN region r ON n1.n_regionkey = r.r_regionkey
        WHERE c.c_custkey = orders.o_custkey
        AND r.r_name = 'ASIA'
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON orders TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
SET ROLE alice;

-- Step 6: Run Q8
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    o_year,
    sum(case
        when nation = 'INDIA' then volume
        else 0
    end) / sum(volume) as mkt_share
from
    (
        select
            extract(year from o_orderdate) as o_year,
            l_extendedprice * (1 - l_discount) as volume,
            n2.n_name as nation
        from
            part,
            supplier,
            lineitem,
            orders,
            customer,
            nation n1,
            nation n2,
            region
        where
            p_partkey = l_partkey
            and s_suppkey = l_suppkey
            and l_orderkey = o_orderkey
            and o_custkey = c_custkey
            and c_nationkey = n1.n_nationkey
            and n1.n_regionkey = r_regionkey
            and r_name = 'ASIA'
            and s_nationkey = n2.n_nationkey
            and o_orderdate between date '1995-01-01' and date '1996-12-31'
            and p_type = 'ECONOMY ANODIZED STEEL'
    ) as all_nations
group by
    o_year
order by
    o_year;