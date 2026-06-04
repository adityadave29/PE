RESET ROLE;
ALTER TABLE customer DISABLE ROW LEVEL SECURITY;

DROP VIEW IF EXISTS customer_secure;

CREATE VIEW customer_secure AS
SELECT c.*
FROM customer c
WHERE substring(c_phone from 1 for 2) IN ('13', '31', '23', '29', '30', '18', '17')
AND c_acctbal > 0.00;

GRANT SELECT ON customer_secure TO alice;
GRANT SELECT ON orders TO alice;
SET ROLE alice;

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
        cntrycode,
        count(*) as numcust,
        sum(c_acctbal) as totacctbal
from
        (
                select
                        substring(c_phone from 1 for 2) as cntrycode,
                        c_acctbal
                from
                        customer_secure c
                where
                        substring(c_phone from 1 for 2) in
                                ('13', '31', '23', '29', '30', '18', '17')
                        and c_acctbal > (
                                select
                                        avg(c_acctbal)
                                from
                                        customer_secure
                                where
                                        c_acctbal > 0.00
                                        and substring(c_phone from 1 for 2) in
                                                ('13', '31', '23', '29', '30', '18', '17')
                        )
                        and not exists (
                                select
                                        *
                                from
                                        orders
                                where
                                        o_custkey = c.c_custkey
                        )
        ) as custsale
group by
        cntrycode
order by
        cntrycode;