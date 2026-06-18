-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS lineitem_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW lineitem_secure AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1 FROM supplier s
    WHERE s.s_suppkey = l.l_suppkey
    AND s.s_acctbal > 1000
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON lineitem_secure TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 5: Run Q6
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    sum(l_extendedprice * l_discount) as revenue
from
    lineitem_secure
where
    l_shipdate >= date '1993-01-01'
    and l_shipdate < date '1994-03-01' + interval '1' year
    and l_discount between 0.06 - 0.01 and 0.06 + 0.01
    and l_quantity < 10;