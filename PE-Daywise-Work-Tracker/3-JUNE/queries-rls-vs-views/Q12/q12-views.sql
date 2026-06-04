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
GRANT SELECT ON orders TO alice;
GRANT SELECT ON supplier TO alice;
SET ROLE alice;

-- Step 5: Run Q12
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    l_shipmode,
    sum(case
        when o_orderpriority = '1-URGENT'
            or o_orderpriority = '2-HIGH'
            then 1
        else 0
    end) as high_line_count,
    sum(case
        when o_orderpriority <> '1-URGENT'
            and o_orderpriority <> '2-HIGH'
            then 1
        else 0
    end) as low_line_count
from
    orders,
    lineitem_secure l
where
    o_orderkey = l.l_orderkey
    and l.l_shipmode = 'SHIP'
    and l.l_commitdate < l.l_receiptdate
    and l.l_shipdate < l.l_commitdate
    and l.l_receiptdate >= date '1995-01-01'
    and l.l_receiptdate < date '1995-01-01' + interval '1' year
group by
    l.l_shipmode
order by
    l.l_shipmode;