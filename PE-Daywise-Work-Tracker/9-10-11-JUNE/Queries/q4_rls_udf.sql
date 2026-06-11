-- Step 1: Drop all existing policies
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT policyname, tablename
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format(
            'DROP POLICY IF EXISTS %I ON %I',
            r.policyname,
            r.tablename
        );
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

-- Step 3: Create UDF
CREATE OR REPLACE FUNCTION customer_acctbal_check(custkey INT)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_custkey = custkey
          AND c.c_acctbal > 5000
    );
$$;

-- Step 4: Enable RLS on orders
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Step 5: Create policy using UDF
CREATE POLICY orders_rls_policy
ON orders
USING (
    customer_acctbal_check(o_custkey)
);

-- Step 6: Grant permissions and set role
GRANT SELECT ON orders TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON lineitem TO alice;

SET ROLE alice;

-- Step 7: Run Q4
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM orders
WHERE o_orderdate >= DATE '1994-01-01'
  AND o_orderdate < DATE '1994-01-01' + INTERVAL '3' MONTH
  AND EXISTS (
      SELECT *
      FROM lineitem
      WHERE l_orderkey = o_orderkey
        AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority
ORDER BY o_orderpriority;