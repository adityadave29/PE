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

-- Step 4: Create policy — only show suppliers from INDIA
CREATE POLICY supplier_rls_policy ON supplier
USING (
    EXISTS (
        SELECT 1 FROM nation n
        WHERE n.n_nationkey = supplier.s_nationkey
        AND n.n_name = 'INDIA'
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 6: Run Q11
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    ps_partkey, n_name,
    SUM(ps_supplycost * ps_availqty) AS total_value
FROM
    partsupp, supplier, nation
WHERE
    ps_suppkey = s_suppkey
    and s_nationkey = n_nationkey
    and n_name = 'INDIA'
GROUP BY
    ps_partkey, n_name
HAVING
    SUM(ps_supplycost * ps_availqty) > (
        SELECT SUM(ps_supplycost * ps_availqty) * 0.00001
        FROM partsupp, supplier, nation
        WHERE
            ps_suppkey = s_suppkey
            and s_nationkey = n_nationkey
            and n_name = 'INDIA'
    )
ORDER BY
    total_value DESC;