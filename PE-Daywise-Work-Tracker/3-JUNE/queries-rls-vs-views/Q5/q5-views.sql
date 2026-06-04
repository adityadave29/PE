-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE customer DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS customer_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW customer_secure AS
SELECT c.*
FROM customer c
WHERE EXISTS (
    SELECT 1 FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_nationkey = c.c_nationkey
    AND r.r_name = 'ASIA'
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON customer_secure TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
SET ROLE alice;

-- Step 5: Run Q5
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    n_name,
    sum(l_extendedprice * (1 - l_discount)) as revenue
from
    customer_secure c,
    orders,
    lineitem,
    supplier,
    nation,
    region
where
    c.c_custkey = o_custkey
    and l_orderkey = o_orderkey
    and l_suppkey = s_suppkey
    and c.c_nationkey = s_nationkey
    and s_nationkey = n_nationkey
    and n_regionkey = r_regionkey
    and r_name = 'ASIA'
    and o_orderdate >= date '1995-01-01'
    and o_orderdate < date '1995-01-01' + interval '1' year
group by
    n_name
order by
    revenue desc;