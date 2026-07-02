-- STEP 1: Cleanup
DROP VIEW IF EXISTS lineitem_view CASCADE;
RESET ROLE;

-- STEP 2: Plain view, no security_barrier
CREATE VIEW lineitem_view AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.o_orderkey = l.l_orderkey
    AND o.o_orderpriority IN ('1-URGENT', '2-HIGH')
);

-- STEP 3: Grants
GRANT SELECT ON lineitem_view TO alice;
GRANT SELECT ON orders TO alice;

-- STEP 4: Benchmark
SET ROLE alice;

-- EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT sum(l_extendedprice * l_discount) AS revenue
FROM lineitem_view
WHERE l_quantity::text ~ '^[1-9]$';

RESET ROLE;