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
    AND n.n_name IN ('FRANCE', 'GERMANY')
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON customer TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

-- Step 5: Run Q7
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    supp_nation,
    cust_nation,
    l_year,
    sum(volume) as revenue
from
    (
        select
            n1.n_name as supp_nation,
            n2.n_name as cust_nation,
            extract(year from l_shipdate) as l_year,
            l_extendedprice * (1 - l_discount) as volume
        from
            supplier_secure s,
            lineitem,
            orders,
            customer,
            nation n1,
            nation n2
        where
            s.s_suppkey = l_suppkey
            and o_orderkey = l_orderkey
            and c_custkey = o_custkey
            and s.s_nationkey = n1.n_nationkey
            and c_nationkey = n2.n_nationkey
            and (
                (n1.n_name = 'GERMANY' and n2.n_name = 'FRANCE')
                or (n1.n_name = 'FRANCE' and n2.n_name = 'GERMANY')
            )
            and l_shipdate between date '1995-01-01' and date '1996-12-31'
    ) as shipping
group by
    supp_nation,
    cust_nation,
    l_year
order by
    supp_nation,
    cust_nation,
    l_year;
    