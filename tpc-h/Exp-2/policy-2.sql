-- Policy 2: supplier table
-- Only suppliers with good financial standing AND from Europe.

ALTER TABLE supplier ENABLE ROW LEVEL SECURITY;

CREATE POLICY supplier_policy ON supplier
USING (
    s_acctbal > 0
    AND s_nationkey IN (
        SELECT n_nationkey 
        FROM nation 
        WHERE n_regionkey IN (
            SELECT r_regionkey 
            FROM region 
            WHERE r_name = 'EUROPE'
        )
    )
);