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

-- Step 4: Create policy — only show lineitems from suppliers with account balance > 1000
CREATE POLICY lineitem_rls_policy ON lineitem
USING (
    EXISTS (
        SELECT 1 FROM supplier s
        WHERE s.s_suppkey = lineitem.l_suppkey
        AND s.s_acctbal > 1000
    )
);

-- Step 5: Grant permissions
GRANT SELECT ON lineitem TO current_user;
GRANT SELECT ON supplier TO current_user;

-- Step 6: Run Q1 with timing
\timing on
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    l_returnflag,
    l_linestatus,
    sum(l_quantity) as sum_qty,
    sum(l_extendedprice) as sum_base_price,
    sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
    avg(l_quantity) as avg_qty,
    avg(l_extendedprice) as avg_price,
    avg(l_discount) as avg_disc,
    count(*) as count_order
from
    lineitem
where
    l_shipdate <= date '1998-12-01' - interval '3' day
group by
    l_returnflag,
    l_linestatus
order by
    l_returnflag,
    l_linestatus;