--------------------------------------------------
-- Disable RLS
--------------------------------------------------

RESET ROLE;

DROP POLICY IF EXISTS lineitem_rls_policy ON lineitem;

ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

--------------------------------------------------
-- Recreate View (Correlated)
--------------------------------------------------

DROP VIEW IF EXISTS lineitem_secure;

CREATE VIEW lineitem_secure AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1
    FROM supplier s
    WHERE s.s_suppkey = l.l_suppkey
      AND s.s_acctbal > 1000
);

--------------------------------------------------
-- Permissions
--------------------------------------------------

GRANT SELECT ON lineitem_secure TO alice;
GRANT SELECT ON supplier TO alice;

SET ROLE alice;

--------------------------------------------------
-- User Query
--------------------------------------------------

EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
SELECT COUNT(*)
FROM (
    SELECT l_orderkey, l_linenumber
    FROM lineitem_secure
    WHERE l_orderkey > 2000000
) l_alias;