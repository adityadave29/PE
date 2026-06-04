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
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE n.n_nationkey = s.s_nationkey
    AND r.r_name = 'EUROPE'
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON region TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON partsupp TO alice;
SET ROLE alice;

-- Step 5: Run Q2 with timing
\timing on
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    s_acctbal,
    s_name,
    n_name,
    p_partkey,
    p_mfgr,
    s_address,
    s_phone,
    s_comment
from
    part,
    supplier_secure s,
    partsupp,
    nation,
    region
where
    p_partkey = ps_partkey
    and s.s_suppkey = ps_suppkey
    and p_size = 15
    and p_type like '%BRASS'
    and s.s_nationkey = n_nationkey
    and n_regionkey = r_regionkey
    and r_name = 'EUROPE'
    and ps_supplycost = (
        select
            min(ps_supplycost)
        from
            partsupp,
            supplier_secure s2,
            nation,
            region
        where
            p_partkey = ps_partkey
            and s2.s_suppkey = ps_suppkey
            and s2.s_nationkey = n_nationkey
            and n_regionkey = r_regionkey
            and r_name = 'EUROPE'
    )
order by
    s_acctbal desc,
    n_name,
    s.s_name,
    p_partkey limit 100;