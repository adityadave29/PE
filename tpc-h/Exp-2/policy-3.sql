-- Policy 3: partsupp table
-- Only records where stock is plentiful AND linked supplier is financially stable.

ALTER TABLE partsupp ENABLE ROW LEVEL SECURITY;

CREATE POLICY partsupp_policy ON partsupp
USING (
    ps_availqty > 100
    AND ps_suppkey IN (
        SELECT s_suppkey 
        FROM supplier 
        WHERE s_acctbal > 0
    )
);