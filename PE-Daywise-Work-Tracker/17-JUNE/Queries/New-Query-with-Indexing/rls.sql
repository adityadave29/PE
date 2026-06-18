--------------------------------------------------
-- Create Index
--------------------------------------------------

CREATE INDEX l_pk
ON lineitem (l_orderkey, l_linenumber);

--------------------------------------------------
-- RLS Policy
--------------------------------------------------

ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineitem_rls_policy
ON lineitem
USING (
    EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_acctbal > 1000
    )
);

GRANT SELECT ON lineitem TO alice;
GRANT SELECT ON supplier TO alice;

SET ROLE alice;

--------------------------------------------------
-- User Query
--------------------------------------------------

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT COUNT(*)
FROM (
    SELECT l_orderkey, l_linenumber
    FROM lineitem
    WHERE l_orderkey > 2000000
) l_alias;