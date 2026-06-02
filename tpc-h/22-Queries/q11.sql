EXPLAIN (ANALYZE, FORMAT TEXT)
SELECT
    ps_partkey, n_name,
    SUM(ps_supplycost * ps_availqty) AS total_value
FROM
    partsupp, supplier, nation 
where
    ps_suppkey = s_suppkey
        and s_nationkey = n_nationkey
        and n_name = 'INDIA'
GROUP BY
    ps_partkey, n_name
HAVING
    SUM(ps_supplycost * ps_availqty) > (
        SELECT SUM(ps_supplycost * ps_availqty) * 0.00001
        FROM partsupp, supplier, nation WHERE 
        ps_suppkey = s_suppkey
        and s_nationkey = n_nationkey
        and n_name = 'INDIA'
    )
ORDER BY
    total_value DESC;
-- Planning Time: 5.200 ms
-- Execution Time: 292.894 ms