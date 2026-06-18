-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS lineitem_secure;

-- Step 3: Create equivalent view
CREATE VIEW lineitem_secure AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1
    FROM supplier s
    WHERE s.s_acctbal > 1000
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON lineitem_secure TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 5: Simple query
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT count(*)
FROM lineitem_secure;