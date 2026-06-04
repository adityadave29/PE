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
    JOIN nation n1 ON c.c_nationkey = n1.n_nationkey
    JOIN region r ON n1.n_regionkey = r.r_regionkey
    WHERE c.c_custkey = o.o_custkey
    AND r.r_name = 'ASIA'
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON orders_secure TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON supplier TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
SET ROLE alice;

-- Step 5: Run Q8
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    o_year,
    sum(case
        when nation = 'INDIA' then volume
        else 0
    end) / sum(volume) as mkt_share
from
    (
        select
            extract(year from o_orderdate) as o_year,
            l_extendedprice * (1 - l_discount) as volume,
            n2.n_name as nation
        from
            part,
            supplier,
            lineitem,
            orders_secure o,
            customer,
            nation n1,
            nation n2,
            region
        where
            p_partkey = l_partkey
            and s_suppkey = l_suppkey
            and l_orderkey = o.o_orderkey
            and o.o_custkey = c_custkey
            and c_nationkey = n1.n_nationkey
            and n1.n_regionkey = r_regionkey
            and r_name = 'ASIA'
            and s_nationkey = n2.n_nationkey
            and o.o_orderdate between date '1995-01-01' and date '1996-12-31'
            and p_type = 'ECONOMY ANODIZED STEEL'
    ) as all_nations
group by
    o_year
order by
    o_year;