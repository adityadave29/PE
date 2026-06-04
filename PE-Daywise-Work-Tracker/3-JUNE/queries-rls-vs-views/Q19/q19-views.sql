-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE part DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS part_secure;

-- Step 3: Create secure view
CREATE VIEW part_secure AS
SELECT p.*
FROM part p
WHERE
  (
    p.p_brand = 'Brand#12'
    AND p.p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
    AND p.p_size BETWEEN 1 AND 5
  ) OR (
    p.p_brand = 'Brand#23'
    AND p.p_container IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
    AND p.p_size BETWEEN 1 AND 10
  ) OR (
    p.p_brand = 'Brand#34'
    AND p.p_container IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
    AND p.p_size BETWEEN 1 AND 15
  );

-- Step 4: Grant permissions and set role
GRANT SELECT ON part_secure TO alice;
GRANT SELECT ON lineitem    TO alice;
SET ROLE alice;

-- Step 5: Run Q19
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
  sum(l_extendedprice * (1 - l_discount)) AS revenue
FROM
  lineitem,
  part_secure p
WHERE
  (
    p.p_partkey = l_partkey
    AND p.p_brand = 'Brand#12'
    AND p.p_container IN ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG')
    AND l_quantity >= 1 AND l_quantity <= 1 + 10
    AND p.p_size BETWEEN 1 AND 5
    AND l_shipmode IN ('AIR', 'AIR REG')
    AND l_shipinstruct = 'DELIVER IN PERSON'
  ) OR (
    p.p_partkey = l_partkey
    AND p.p_brand = 'Brand#23'
    AND p.p_container IN ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK')
    AND l_quantity >= 10 AND l_quantity <= 10 + 10
    AND p.p_size BETWEEN 1 AND 10
    AND l_shipmode IN ('AIR', 'AIR REG')
    AND l_shipinstruct = 'DELIVER IN PERSON'
  ) OR (
    p.p_partkey = l_partkey
    AND p.p_brand = 'Brand#34'
    AND p.p_container IN ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG')
    AND l_quantity >= 20 AND l_quantity <= 20 + 10
    AND p.p_size BETWEEN 1 AND 15
    AND l_shipmode IN ('AIR', 'AIR REG')
    AND l_shipinstruct = 'DELIVER IN PERSON'
  );