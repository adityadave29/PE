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
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 5: Run Q13
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    c_count, c_orderdate,
    count(*) as custdist
from
    (
        select
            c.c_custkey, o_orderdate,
            count(o_orderkey)
        from
            customer_secure c left outer join orders on
                c.c_custkey = o_custkey
                and o_comment not like '%special%requests%'
        group by
            c.c_custkey, o_orderdate
    ) as c_orders (c_custkey, c_count, c_orderdate)
group by
    c_count, c_orderdate
order by
    custdist desc,
    c_count desc;