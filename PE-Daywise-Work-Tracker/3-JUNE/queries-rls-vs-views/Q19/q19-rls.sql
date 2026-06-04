-- Step 1: Drop all existing policies
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT policyname, tablename
    FROM pg_policies
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format(
      'DROP POLICY IF EXISTS %I ON %I',
      r.policyname, r.tablename
    );
  END LOOP;
END;
$$;

-- Step 2: Disable RLS on all tables
RESET ROLE;
ALTER TABLE lineitem  DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders    DISABLE ROW LEVEL SECURITY;
ALTER TABLE customer  DISABLE ROW LEVEL SECURITY;
ALTER TABLE supplier  DISABLE ROW LEVEL SECURITY;
ALTER TABLE part      DISABLE ROW LEVEL SECURITY;
ALTER TABLE partsupp  DISABLE ROW LEVEL SECURITY;
ALTER TABLE nation    DISABLE ROW LEVEL SECURITY;
ALTER TABLE region    DISABLE ROW LEVEL SECURITY;

-- Step 3: Enable RLS on part
ALTER TABLE part ENABLE ROW LEVEL SECURITY;

-- Step 4: Policy — only rows matching
--   Q19 brand/container/size combos
CREATE POLICY part_rls_policy ON part
USING (
  (
    p_brand = 'Brand#12'
    AND p_container IN (
      'SM CASE','SM BOX','SM PACK','SM PKG'
    )
    AND p_size BETWEEN 1 AND 5
  ) OR (
    p_brand = 'Brand#23'
    AND p_container IN (
      'MED BAG','MED BOX','MED PKG','MED PACK'
    )
    AND p_size BETWEEN 1 AND 10
  ) OR (
    p_brand = 'Brand#34'
    AND p_container IN (
      'LG CASE','LG BOX','LG PACK','LG PKG'
    )
    AND p_size BETWEEN 1 AND 15
  )
);

-- Step 5: Grant permissions and set role
GRANT SELECT ON part     TO alice;
GRANT SELECT ON lineitem TO alice;
SET ROLE alice;

-- Step 6: Run Q19
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT
  sum(l_extendedprice * (1 - l_discount))
    AS revenue
FROM lineitem, part
WHERE
  (
    p_partkey = l_partkey
    AND p_brand = 'Brand#12'
    AND p_container IN (
      'SM CASE','SM BOX','SM PACK','SM PKG'
    )
    AND l_quantity >= 1
    AND l_quantity <= 1 + 10
    AND p_size BETWEEN 1 AND 5
    AND l_shipmode IN ('AIR','AIR REG')
    AND l_shipinstruct = 'DELIVER IN PERSON'
  ) OR (
    p_partkey = l_partkey
    AND p_brand = 'Brand#23'
    AND p_container IN (
      'MED BAG','MED BOX','MED PKG','MED PACK'
    )
    AND l_quantity >= 10
    AND l_quantity <= 10 + 10
    AND p_size BETWEEN 1 AND 10
    AND l_shipmode IN ('AIR','AIR REG')
    AND l_shipinstruct = 'DELIVER IN PERSON'
  ) OR (
    p_partkey = l_partkey
    AND p_brand = 'Brand#34'
    AND p_container IN (
      'LG CASE','LG BOX','LG PACK','LG PKG'
    )
    AND l_quantity >= 20
    AND l_quantity <= 20 + 10
    AND p_size BETWEEN 1 AND 15
    AND l_shipmode IN ('AIR','AIR REG')
    AND l_shipinstruct = 'DELIVER IN PERSON'
  );