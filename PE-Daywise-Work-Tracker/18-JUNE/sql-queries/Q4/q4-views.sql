USE TPCH;
GO

--------------------------------------------------
-- Step 1: Drop existing view if present
--------------------------------------------------

IF OBJECT_ID('dbo.orders_secure', 'V') IS NOT NULL
    DROP VIEW dbo.orders_secure;
GO

--------------------------------------------------
-- Step 2: Create view with same filter logic as RLS
--------------------------------------------------

CREATE VIEW dbo.orders_secure
AS
SELECT o.*
FROM dbo.orders o
WHERE EXISTS
(
    SELECT 1
    FROM dbo.customer c
    WHERE c.c_custkey = o.o_custkey
      AND c.c_acctbal > 5000
);
GO

--------------------------------------------------
-- Step 3: Grant permissions
--------------------------------------------------

GRANT SELECT ON dbo.orders_secure TO alice;
GRANT SELECT ON dbo.customer TO alice;
GRANT SELECT ON dbo.lineitem TO alice;
GO

--------------------------------------------------
-- Step 4: Execute as alice
--------------------------------------------------

EXECUTE AS USER = 'alice';
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

--------------------------------------------------
-- Step 5: Run Q4
--------------------------------------------------

SELECT
    o_orderpriority,
    COUNT(*) AS order_count
FROM dbo.orders_secure
WHERE o_orderdate >= '1994-01-01'
  AND o_orderdate < '1994-04-01'
  AND EXISTS
  (
      SELECT 1
      FROM dbo.lineitem
      WHERE l_orderkey = o_orderkey
        AND l_commitdate < l_receiptdate
  )
GROUP BY o_orderpriority
ORDER BY o_orderpriority;
GO

--------------------------------------------------
-- Step 6: Revert user
--------------------------------------------------

REVERT;
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
GO