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
-- Step 2: Create RLS predicate function
--------------------------------------------------

CREATE OR ALTER FUNCTION dbo.lineitem_rls_predicate
(
    @l_suppkey INT
)
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
        WHERE s.s_suppkey = @l_suppkey
          AND s.s_acctbal > 1000
    )
);
GO

--------------------------------------------------
-- Step 3: Create security policy
--------------------------------------------------

CREATE SECURITY POLICY lineitem_rls_policy
ADD FILTER PREDICATE
dbo.lineitem_rls_predicate(l_suppkey)
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
-- Step 6: Run Q6
--------------------------------------------------

SELECT
    SUM(l_extendedprice * l_discount) AS revenue
FROM dbo.lineitem
WHERE l_shipdate >= '1993-01-01'
  AND l_shipdate < '1995-03-01'
  AND l_discount BETWEEN 0.05 AND 0.07
  AND l_quantity < 10;
GO

--------------------------------------------------
-- Step 7: Cleanup
--------------------------------------------------

REVERT;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO