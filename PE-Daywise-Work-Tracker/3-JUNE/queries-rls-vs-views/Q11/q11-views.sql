-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS supplier_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW supplier_secure AS
SELECT s.*
FROM supplier s
WHERE EXISTS (
    SELECT 1 FROM nation n
    WHERE n.n_nationkey = s.s_nationkey
    AND n.n_name = 'INDIA'
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 5: Run Q11
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    ps_partkey, n_name,
    SUM(ps_supplycost * ps_availqty) AS total_value
FROM
    partsupp,
    supplier_secure s,
    nation
WHERE
    ps_suppkey = s.s_suppkey
    and s.s_nationkey = n_nationkey
    and n_name = 'INDIA'
GROUP BY
    ps_partkey, n_name
HAVING
    SUM(ps_supplycost * ps_availqty) > (
        SELECT SUM(ps_supplycost * ps_availqty) * 0.00001
        FROM partsupp, supplier_secure s2, nation
        WHERE
            ps_suppkey = s2.s_suppkey
            and s2.s_nationkey = n_nationkey
            and n_name = 'INDIA'
    )
ORDER BY
    total_value DESC;