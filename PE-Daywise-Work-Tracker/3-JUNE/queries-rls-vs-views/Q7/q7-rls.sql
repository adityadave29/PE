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

-- Step 4: Create policy — only show suppliers from FRANCE or GERMANY
CREATE POLICY supplier_rls_policy ON supplier
USING (
    EXISTS (
        SELECT 1 FROM nation n
        WHERE n.n_nationkey = supplier.s_nationkey
        AND n.n_name IN ('FRANCE', 'GERMANY')
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 6: Run Q7
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    supp_nation,
    cust_nation,
    l_year,
    sum(volume) as revenue
from
    (
        select
            n1.n_name as supp_nation,
            n2.n_name as cust_nation,
            extract(year from l_shipdate) as l_year,
            l_extendedprice * (1 - l_discount) as volume
        from
            supplier,
            lineitem,
            orders,
            customer,
            nation n1,
            nation n2
        where
            s_suppkey = l_suppkey
            and o_orderkey = l_orderkey
            and c_custkey = o_custkey
            and s_nationkey = n1.n_nationkey
            and c_nationkey = n2.n_nationkey
            and (
                (n1.n_name = 'GERMANY' and n2.n_name = 'FRANCE')
                or (n1.n_name = 'FRANCE' and n2.n_name = 'GERMANY')
            )
            and l_shipdate between date '1995-01-01' and date '1996-12-31'
    ) as shipping
group by
    supp_nation,
    cust_nation,
    l_year
order by
    supp_nation,
    cust_nation,
    l_year;