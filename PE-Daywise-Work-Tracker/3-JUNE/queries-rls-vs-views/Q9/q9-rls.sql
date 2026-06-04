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

-- Step 3: Enable RLS on supplier
ALTER TABLE supplier ENABLE ROW LEVEL SECURITY;

-- Step 4: Create policy — only show suppliers with acctbal > 500
CREATE POLICY supplier_rls_policy ON supplier
USING (
    EXISTS (
        SELECT 1 FROM nation n
        WHERE n.n_nationkey = supplier.s_nationkey
        AND supplier.s_acctbal > 500
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 6: Run Q9
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
            l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount
        from
            part,
            supplier,
            lineitem,
            partsupp,
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