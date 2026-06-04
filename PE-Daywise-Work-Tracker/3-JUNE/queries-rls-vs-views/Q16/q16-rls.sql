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

-- Step 3: Enable RLS on partsupp
ALTER TABLE partsupp ENABLE ROW LEVEL SECURITY;

-- Step 4: Create policy — only show partsupp from suppliers with acctbal > 0
CREATE POLICY partsupp_rls_policy ON partsupp
USING (
    EXISTS (
        SELECT 1 FROM supplier s
        WHERE s.s_suppkey = partsupp.ps_suppkey
        AND s.s_acctbal > 0
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 6: Run Q16
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    p_brand,
    p_type,
    p_size,
    count(distinct ps_suppkey) as supplier_cnt
from
    partsupp,
    part
where
    p_partkey = ps_partkey
    and p_brand <> 'Brand#23'
    and p_type not like 'MEDIUM POLISHED%'
    and p_size in (1, 4, 7)
    and ps_suppkey not in (
        select
            s_suppkey
        from
            supplier
        where
            s_comment like '%Customer%Complaints%'
    )
group by
    p_brand,
    p_type,
    p_size
order by
    supplier_cnt desc,
    p_brand,
    p_type,
    p_size;