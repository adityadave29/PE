CREATE OR REPLACE VIEW orders_secure AS
SELECT *
FROM orders
WHERE EXISTS (
    SELECT 1
    FROM customer c
    WHERE c.c_custkey = orders.o_custkey
      AND c.c_acctbal > 5000
);


GRANT SELECT ON orders_secure TO alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM orders_secure
WHERE o_orderdate >= DATE '1994-01-01'
  AND o_orderdate < DATE '1994-01-01' + INTERVAL '3' MONTH
  AND EXISTS (
        SELECT 1
        FROM lineitem
        WHERE l_orderkey = o_orderkey
          AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority
ORDER BY o_orderpriority;


