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
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;

-- Step 3: Enable RLS on lineitem
ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

-- Step 4: Create NON-CORRELATED policy
CREATE POLICY lineitem_rls_policy ON lineitem
USING (
    EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_acctbal > 1000
    )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 6: Simple query
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT count(*)
FROM lineitem;