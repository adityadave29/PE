-- Create UDF (default = PARALLEL UNSAFE)
CREATE OR REPLACE FUNCTION check_supplier_balance_unsafe(acctbal float8)
RETURNS boolean
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN acctbal > 1000;
END;
$$;

-- Drop existing policies
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT policyname, tablename
             FROM pg_policies
             WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I',
                       r.policyname,
                       r.tablename);
    END LOOP;
END;
$$;

RESET ROLE;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;

ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineitem_rls_policy ON lineitem
USING (
    EXISTS (
        SELECT 1
        FROM supplier s
        WHERE check_supplier_balance_unsafe(s.s_acctbal)
    )
);

GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON supplier TO alice;

SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT count(*)
FROM lineitem;