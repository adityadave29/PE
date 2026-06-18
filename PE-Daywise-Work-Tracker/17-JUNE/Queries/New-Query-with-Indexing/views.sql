--------------------------------------------------
-- Disable RLS
--------------------------------------------------

RESET ROLE;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

DROP VIEW IF EXISTS lineitem_secure;

--------------------------------------------------
-- Create View
--------------------------------------------------

CREATE VIEW lineitem_secure AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1
    FROM supplier s
    WHERE s.s_acctbal > 1000
);

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