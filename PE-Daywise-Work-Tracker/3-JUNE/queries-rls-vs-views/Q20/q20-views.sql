RESET ROLE;
ALTER TABLE supplier DISABLE ROW LEVEL SECURITY;

DROP VIEW IF EXISTS supplier_secure;

CREATE VIEW supplier_secure AS
SELECT s.*
FROM supplier s
WHERE EXISTS (
    SELECT 1 FROM nation n
    WHERE n.n_nationkey = s.s_nationkey
    AND n.n_name = 'FRANCE'
);

GRANT SELECT ON supplier_secure TO alice;
GRANT SELECT ON nation TO alice;
GRANT SELECT ON partsupp TO alice;
GRANT SELECT ON part TO alice;
GRANT SELECT ON lineitem TO alice;
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        s_name,
        s_address
from
        supplier_secure s,
        nation
where
        s.s_suppkey in (
                select
                        ps_suppkey
                from
                        partsupp
                where
                        ps_partkey in (
                                select
                                        p_partkey
                                from
                                        part
                                where
                                        p_name like '%ivory%'
                        )
                        and ps_availqty > (
                                select
                                        0.5 * sum(l_quantity)
                                from
                                        lineitem
                                where
                                        l_partkey = ps_partkey
                                        and l_suppkey = ps_suppkey
                                        and l_shipdate >= date '1995-01-01'
                                        and l_shipdate < date '1995-01-01' + interval '1' year
                        )
        )
        and s.s_nationkey = n_nationkey
        and n_name = 'FRANCE'
order by
        s_name;