-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE partsupp DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS partsupp_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW partsupp_secure AS
SELECT ps.*
FROM partsupp ps
WHERE EXISTS (
    SELECT 1 FROM supplier s
    WHERE s.s_suppkey = ps.ps_suppkey
    AND s.s_acctbal > 0
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON partsupp_secure TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 5: Run Q16
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    p_brand,
    p_type,
    p_size,
    count(distinct ps_suppkey) as supplier_cnt
from
    partsupp_secure ps,
    part
where
    p_partkey = ps.ps_partkey
    and p_brand <> 'Brand#23'
    and p_type not like 'MEDIUM POLISHED%'
    and p_size in (1, 4, 7)
    and ps.ps_suppkey not in (
        select
            s_suppkey
        from
            supplier
        where
            s_comment like '%Customer%Complaints%'
    )
group by
    p_brand,
    p_type,
    p_size
order by
    supplier_cnt desc,
    p_brand,
    p_type,
    p_size;