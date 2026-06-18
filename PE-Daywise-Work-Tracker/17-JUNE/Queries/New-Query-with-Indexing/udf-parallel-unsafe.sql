--------------------------------------------------
-- Function
--------------------------------------------------

CREATE OR REPLACE FUNCTION supplier_filter_unsafe()
RETURNS boolean
LANGUAGE sql
PARALLEL UNSAFE
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM supplier
        WHERE s_acctbal > 1000
    );
$$;

--------------------------------------------------
-- RLS
--------------------------------------------------

ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineitem_rls_policy
ON lineitem
USING (supplier_filter_unsafe());

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