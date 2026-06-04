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
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 6: Run Q15
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
with revenue(supplier_no, total_revenue) as
    (select
        l_suppkey,
        sum(l_extendedprice * (1 - l_discount))
    from
        lineitem
    where
        l_shipdate >= date '1995-01-01'
        and l_shipdate < date '1995-01-01' + interval '3' month
    group by
        l_suppkey)
select
    s_suppkey,
    s_name,
    s_address,
    s_phone,
    total_revenue
from
    supplier,
    revenue
where
    s_suppkey = supplier_no
    and total_revenue = (
        select
            max(total_revenue)
        from
            revenue
    )
order by
    s_suppkey;