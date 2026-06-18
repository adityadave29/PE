--------------------------------------------------
-- Create Index
--------------------------------------------------

CREATE INDEX IF NOT EXISTS l_pk
ON lineitem (l_orderkey, l_linenumber);

--------------------------------------------------
-- Remove Existing Policy
--------------------------------------------------

RESET ROLE;

DROP POLICY IF EXISTS lineitem_rls_policy ON lineitem;

ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;
ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

--------------------------------------------------
-- Correlated RLS Policy
--------------------------------------------------

CREATE POLICY lineitem_rls_policy
ON lineitem
USING (
    EXISTS (
        SELECT 1
        FROM supplier s
        WHERE s.s_suppkey = lineitem.l_suppkey
          AND s.s_acctbal > 1000
    )
);

--------------------------------------------------
-- Permissions
--------------------------------------------------

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