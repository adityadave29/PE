-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS orders_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW orders_secure AS
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

-- EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
EXPLAIN (
  ANALYZE true,
  VERBOSE true,
  COSTS true,
  BUFFERS false,
  TIMING false,
  FORMAT JSON
)
select
    o_orderpriority,
    count(*) as order_count
from
    orders_secure
where
    o_orderdate >= date '1994-01-01'
    and o_orderdate < date '1994-01-01' + interval '3' month
    and exists (
        select
            *
        from
            lineitem
        where
            l_orderkey = o_orderkey
            and l_commitdate < l_receiptdate
    )
group by
    o_orderpriority
order by
    o_orderpriority;

-- Planning Time: 8.632 ms
-- Execution Time: 1489.721 ms


-- o_orderpriority | order_count 
-----------------+-------------
-- 1-URGENT        |        4751
-- 2-HIGH          |        4737
-- 3-MEDIUM        |        4661
-- 4-NOT SPECIFIED |        4591
-- 5-LOW           |        4577
-- (5 rows)

SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM orders
WHERE
    /* RLS policy */
    EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_custkey = orders.o_custkey
          AND c.c_acctbal > 5000
    )

    /* Original query predicates */
    AND o_orderdate >= DATE '1994-01-01'

    AND o_orderdate <
        DATE '1994-01-01' + INTERVAL '3 month'

    AND EXISTS (
        SELECT *
        FROM lineitem
        WHERE l.l_orderkey = orders.o_orderkey
          AND l.l_commitdate < l.l_receiptdate
    )

GROUP BY o_orderpriority
ORDER BY o_orderpriority;
