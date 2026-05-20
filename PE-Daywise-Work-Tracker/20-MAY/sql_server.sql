
DROP SECURITY POLICY IF EXISTS CustomerPolicy;
DROP SECURITY POLICY IF EXISTS OrderPolicy;
GO

DROP FUNCTION IF EXISTS dbo.fn_customer_access;
DROP FUNCTION IF EXISTS dbo.fn_order_access;
GO

DROP TABLE IF EXISTS dbo.Orders;
DROP TABLE IF EXISTS dbo.Customers;
GO

DROP USER IF EXISTS alice;
GO


CREATE TABLE dbo.Customers (
    id INT PRIMARY KEY,
    name NVARCHAR(50)
);

CREATE TABLE dbo.Orders (
    order_id INT PRIMARY KEY,
    customer_id INT FOREIGN KEY REFERENCES dbo.Customers(id)
);

INSERT INTO dbo.Customers (id, name) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Carol'),
(4, 'David'),
(5, 'Eve'),
(6, 'Frank'),
(7, 'Grace'),
(8, 'Hank'),
(9, 'Ivy'),
(10, 'Jack');

INSERT INTO dbo.Orders (order_id, customer_id) VALUES
(1, 1),
(2, 1),
(3, 2),
(4, 3),
(5, 5),
(6, 5),
(7, 7),
(8, 8),
(9, 8),
(10, 10);
GO

CREATE USER alice WITHOUT LOGIN;
GO

GRANT SELECT ON dbo.Customers TO alice;
GRANT SELECT ON dbo.Orders TO alice;
GO

CREATE FUNCTION dbo.fn_customer_access (@custid INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS result
    WHERE EXISTS (
        SELECT 1
        FROM dbo.Orders o
        WHERE o.customer_id = @custid
    )
);
GO

CREATE FUNCTION dbo.fn_order_access (@custid INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS result
    WHERE EXISTS (
        SELECT 1
        FROM dbo.Customers c
        WHERE c.id = @custid
    )
);
GO

CREATE SECURITY POLICY CustomerPolicy
ADD FILTER PREDICATE dbo.fn_customer_access(id)
ON dbo.Customers
WITH (STATE = ON);
GO

CREATE SECURITY POLICY OrderPolicy
ADD FILTER PREDICATE dbo.fn_order_access(customer_id)
ON dbo.Orders
WITH (STATE = ON);
GO

EXECUTE AS USER = 'alice';
GO

SELECT * FROM dbo.Customers;
GO






Output:
same as postgres with RLS (with SECURITY DEFINER).
