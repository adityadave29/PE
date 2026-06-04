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
    WHERE n.n_nationkey = c.c_nationkey
    AND c.c_acctbal > 0
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON customer_secure TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 5: Run Q10
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    c_custkey,
    c_name,
    sum(l_extendedprice * (1 - l_discount)) as revenue,
    c_acctbal,
    n_name,
    c_address,
    c_phone,
    c_comment
from
    customer_secure c,
    orders,
    lineitem,
    nation
where
    c.c_custkey = o_custkey
    and l_orderkey = o_orderkey
    and o_orderdate >= date '1995-01-01'
    and o_orderdate < date '1995-01-01' + interval '3' month
    and l_returnflag = 'R'
    and c.c_nationkey = n_nationkey
group by
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    c.c_phone,
    n_name,
    c.c_address,
    c.c_comment
order by
    revenue desc;