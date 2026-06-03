-- Remove all existing policies
DROP POLICY IF EXISTS orders_policy   ON orders;
DROP POLICY IF EXISTS customer_policy ON customer;
DROP POLICY IF EXISTS supplier_policy ON supplier;
DROP POLICY IF EXISTS lineitem_policy ON lineitem;
DROP POLICY IF EXISTS partsupp_policy ON partsupp;
DROP POLICY IF EXISTS part_policy     ON part;

-- Disable RLS everywhere
ALTER TABLE orders   DISABLE ROW LEVEL SECURITY;
ALTER TABLE customer DISABLE ROW LEVEL SECURITY;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;
ALTER TABLE partsupp DISABLE ROW LEVEL SECURITY;
ALTER TABLE part     DISABLE ROW LEVEL SECURITY;

-- Verify
SELECT * FROM pg_policies;

-- Enable RLS only on ORDERS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Create the policy we used for Q4
CREATE POLICY orders_policy
ON orders
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_custkey = orders.o_custkey
          AND c.c_acctbal > 5000
    )
);

GRANT SELECT ON orders, customer, lineitem TO tpch_user;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM orders
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


