-- Customer: attribute + one subquery join
CREATE POLICY customer_policy ON customer
USING (
    c_acctbal > 0
    AND c_nationkey IN (
        SELECT n_nationkey FROM nation
        WHERE n_regionkey < 4
    )
);

-- Supplier: attribute + one subquery join  
CREATE POLICY supplier_policy ON supplier
USING (
    s_acctbal > 0
    AND s_nationkey IN (
        SELECT n_nationkey FROM nation
        WHERE n_regionkey < 3
    )
);

-- Partsupp: two simple attribute predicates
CREATE POLICY partsupp_policy ON partsupp
USING (
    ps_availqty > 50
    AND ps_supplycost < 1000
);

-- Lineitem: two simple attribute predicates (NO subquery)
CREATE POLICY lineitem_policy ON lineitem
USING (
    l_quantity > 1
    AND l_discount < 0.08
);
