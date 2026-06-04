-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS supplier_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW supplier_secure AS
SELECT s.*
FROM supplier s
WHERE EXISTS (
    SELECT 1 FROM nation n
    WHERE n.n_nationkey = s.s_nationkey
    AND s.s_acctbal > 500
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 5: Run Q9
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    nation,
    o_year,
    sum(amount) as sum_profit
from
    (
        select
            n_name as nation,
            p_name,
            extract(year from o_orderdate) as o_year,
            l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount
        from
            part,
            supplier_secure s,
            lineitem,
            partsupp,
            orders,
            nation
        where
            s.s_suppkey = l_suppkey
            and ps_suppkey = l_suppkey
            and ps_partkey = l_partkey
            and p_partkey = l_partkey
            and o_orderkey = l_orderkey
            and s.s_nationkey = n_nationkey
            and p_name like 'co%'
    ) as profit
group by
    nation,
    o_year
order by
    nation,
    o_year desc;