-- Step 1: Reset role and disable RLS
RESET ROLE;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS lineitem_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW lineitem_secure AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1 FROM supplier s
    WHERE s.s_suppkey = l.l_suppkey
    AND s.s_acctbal > 1000
);

-- Step 4: Grant permissions and set role
GRANT SELECT ON lineitem_secure TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 5: Run Q15
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
with revenue(supplier_no, total_revenue) as
    (select
        l.l_suppkey,
        sum(l.l_extendedprice * (1 - l.l_discount))
    from
        lineitem_secure l
    where
        l.l_shipdate >= date '1995-01-01'
        and l.l_shipdate < date '1995-01-01' + interval '3' month
    group by
        l.l_suppkey)
select
    s_suppkey,
    s_name,
    s_address,
    s_phone,
    total_revenue
from
    supplier,
    revenue
where
    s_suppkey = supplier_no
    and total_revenue = (
        select
            max(total_revenue)
        from
            revenue
    )
order by
    s_suppkey;