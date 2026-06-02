EXPLAIN (ANALYZE, FORMAT TEXT)
select
        sum(l_extendedprice * l_discount) as revenue
from lineitem
where
        l_shipdate >= date '1993-01-01'
        and l_shipdate < date '1994-03-01' + interval '1' year
        and l_discount between 0.06 - 0.01 and 0.06 + 0.01
        and l_quantity < 10;

-- Planning Time: 3.189 ms
--  Execution Time: 605.717 ms