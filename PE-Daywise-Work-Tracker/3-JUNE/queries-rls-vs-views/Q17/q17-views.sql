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
GRANT SELECT ON part TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 5: Run Q17
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select sum(l.l_extendedprice) / 7.0 as avg_yearly
from
    lineitem_secure l,
    part
where
    p_partkey = l.l_partkey
    and p_brand = 'Brand#53'
    and p_container = 'MED BAG'
    and l.l_quantity < (
        select
            0.7 * avg(l2.l_quantity)
        from
            lineitem_secure l2
        where
            l2.l_partkey = p_partkey
    );