-- Policy 4: lineitem table
-- Only line items from high-priority orders AND with plentiful stock.

ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineitem_policy ON lineitem
USING (
    l_orderkey IN (
        SELECT o_orderkey 
        FROM orders 
        WHERE o_orderpriority = '1-URGENT'
    )
    AND l_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_availqty > 100
    )
);