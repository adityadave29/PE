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

-- Step 5: Run Q14
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    100.00 * sum(case
        when p_type like 'PROMO%'
            then l_extendedprice * (1 - l_discount)
        else 0
    end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue
from
    lineitem_secure l,
    part
where
    l.l_partkey = p_partkey
    and l.l_shipdate >= date '1995-01-01'
    and l.l_shipdate < date '1995-01-01' + interval '1' month;