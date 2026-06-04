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

-- Step 5: Run Q18
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    c_name,
    c_custkey,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    sum(l_quantity)
from
    customer,
    orders_secure o,
    lineitem
where
    o.o_orderkey in (
        select
            l_orderkey
        from
            lineitem
        group by
            l_orderkey having
                sum(l_quantity) > 300
    )
    and c_custkey = o.o_custkey
    and o.o_orderkey = l_orderkey
group by
    c_name,
    c_custkey,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice
order by
    o.o_totalprice desc,
    o.o_orderdate;