-- Policy 1: customer table
-- Only customers with high purchasing power AND from approved business regions.

ALTER TABLE customer ENABLE ROW LEVEL SECURITY;

CREATE POLICY customer_policy ON customer
USING (
    c_acctbal > 0
    AND c_nationkey IN (
        SELECT n_nationkey 
        FROM nation 
        WHERE n_regionkey IN (
            SELECT r_regionkey 
            FROM region 
            WHERE r_name IN ('ASIA', 'EUROPE', 'AMERICA')
        )
    )
);

