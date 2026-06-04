-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS orders_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW orders_secure AS
SELECT o.*
FROM orders o
WHERE EXISTS (
    SELECT 1 FROM customer c
    WHERE c.c_custkey = o.o_custkey
    AND c.c_acctbal > 5000
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON orders_secure TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON lineitem TO alice;
SET ROLE alice;

-- Step 5: Run Q4 with timing
\timing on
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    o_orderpriority,
    count(*) as order_count
from
    orders_secure
where
    o_orderdate >= date '1994-01-01'
    and o_orderdate < date '1994-01-01' + interval '3' month
    and exists (
        select
            *
        from
            lineitem
        where
            l_orderkey = o_orderkey
            and l_commitdate < l_receiptdate
    )
group by
    o_orderpriority
order by
    o_orderpriority;