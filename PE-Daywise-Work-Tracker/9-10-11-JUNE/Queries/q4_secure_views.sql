-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS orders_secure;

-- Step 3: Create SECURITY BARRIER view with same filter logic as RLS policy
CREATE VIEW orders_secure WITH (security_barrier = true) AS
SELECT o.*
FROM orders o
WHERE EXISTS (
    SELECT 1 FROM customer c
    WHERE c.c_custkey = o.o_custkey
    AND c.c_acctbal > 5000
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON orders_secure TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON lineitem TO alice;
SET ROLE alice;

-- Step 5: Run Q4 with timing
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM
    orders_secure
WHERE
    o_orderdate >= DATE '1994-01-01'
    AND o_orderdate < DATE '1994-01-01' + INTERVAL '3' MONTH
    AND EXISTS (
        SELECT *
        FROM lineitem
        WHERE l_orderkey = o_orderkey
          AND l_commitdate < l_receiptdate
    )
GROUP BY
    o_orderpriority
ORDER BY
    o_orderpriority;


-- o_orderpriority | order_count 
-----------------+-------------
-- 1-URGENT        |        4751
-- 2-HIGH          |        4737
-- 3-MEDIUM        |        4661
-- 4-NOT SPECIFIED |        4591
-- 5-LOW           |        4577
-- (5 rows)


--  Planning Time: 7.507 ms
-- Execution Time: 1623.323 ms
    