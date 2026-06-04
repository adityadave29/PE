RESET ROLE;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;

DROP VIEW IF EXISTS supplier_secure;

CREATE VIEW supplier_secure AS
SELECT s.*
FROM supplier s
WHERE EXISTS (
    SELECT 1 FROM nation n
    WHERE n.n_nationkey = s.s_nationkey
    AND n.n_name = 'ARGENTINA'
);

GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON orders TO alice;
GRANT SELECT ON nation TO alice;
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        s_name,
        count(*) as numwait
from
        supplier_secure s,
        lineitem l1,
        orders,
        nation
where
        s.s_suppkey = l1.l_suppkey
        and o_orderkey = l1.l_orderkey
        and o_orderstatus = 'F'
        and l1.l_receiptdate > l1.l_commitdate
        and exists (
                select
                        *
                from
                        lineitem l2
                where
                        l2.l_orderkey = l1.l_orderkey
                        and l2.l_suppkey <> l1.l_suppkey
        )
        and not exists (
                select
                        *
                from
                        lineitem l3
                where
                        l3.l_orderkey = l1.l_orderkey
                        and l3.l_suppkey <> l1.l_suppkey
                        and l3.l_receiptdate > l3.l_commitdate
        )
        and s.s_nationkey = n_nationkey
        and n_name = 'ARGENTINA'
group by
        s_name
order by
        numwait desc,
        s_name;