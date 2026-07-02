-- ============================================================
-- BOX 2: SECURE VIEW (security_barrier = true)
-- ============================================================

-- STEP 1: Cleanup
DROP VIEW IF EXISTS lineitem_secure CASCADE;
DROP FUNCTION IF EXISTS leaky_lt(numeric, numeric);
RESET ROLE;

-- STEP 2: Leaky function (default = NOT LEAKPROOF)
CREATE FUNCTION leaky_lt(a numeric, b numeric)
RETURNS boolean AS $$
  SELECT a < b;
$$ LANGUAGE sql;

-- STEP 3: Secure view, security_barrier = true
CREATE VIEW lineitem_secure WITH (security_barrier = true) AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.o_orderkey = l.l_orderkey
    AND o.o_orderpriority IN ('1-URGENT', '2-HIGH')
);

-- STEP 4: Grants
GRANT SELECT ON lineitem_secure TO alice;
GRANT SELECT ON orders TO alice;
GRANT EXECUTE ON FUNCTION leaky_lt(numeric, numeric) TO alice;

-- STEP 5: Benchmark
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT sum(l_extendedprice * l_discount) AS revenue
FROM lineitem_secure
WHERE leaky_lt(l_quantity, 10);

RESET ROLE;