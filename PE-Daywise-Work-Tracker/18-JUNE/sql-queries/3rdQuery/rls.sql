USE TPCH;
GO

--------------------------------------------------
-- Step 1: Drop existing security policy
--------------------------------------------------

IF EXISTS (
    SELECT *
    FROM sys.security_policies
    WHERE name = 'lineitem_rls_policy'
)
BEGIN
    DROP SECURITY POLICY lineitem_rls_policy;
END
GO

--------------------------------------------------
-- Step 2: Create NON-CORRELATED predicate function
--------------------------------------------------

CREATE OR ALTER FUNCTION dbo.lineitem_rls_predicate()
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS fn_result
    WHERE EXISTS
    (
        SELECT 1
        FROM dbo.supplier s
        WHERE s.s_acctbal > 1000
    )
);
GO

--------------------------------------------------
-- Step 3: Create security policy
--------------------------------------------------

CREATE SECURITY POLICY lineitem_rls_policy
ADD FILTER PREDICATE
dbo.lineitem_rls_predicate()
ON dbo.lineitem
WITH (STATE = ON);
GO

--------------------------------------------------
-- Step 4: Grant permissions
--------------------------------------------------

GRANT SELECT ON dbo.lineitem TO alice;
GRANT SELECT ON dbo.supplier TO alice;
GO

--------------------------------------------------
-- Step 5: Execute as alice
--------------------------------------------------

EXECUTE AS USER = 'alice';
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

--------------------------------------------------
-- Step 6: Simple query
--------------------------------------------------

SELECT COUNT(*)
FROM dbo.lineitem;
GO

--------------------------------------------------
-- Step 7: Cleanup
--------------------------------------------------

REVERT;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO