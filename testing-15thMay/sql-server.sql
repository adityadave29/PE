CREATE DATABASE testing;
GO

USE testing;
GO

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100)
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT
);

INSERT INTO Customers VALUES
(1, 'Alice'),
(2, 'Bob');

INSERT INTO Orders VALUES
(101, 1),
(102, 2);

CREATE LOGIN alice WITH PASSWORD = 'Alice@123';
GO

USE testing;
GO

CREATE USER alice FOR LOGIN alice;
GO

GRANT SELECT ON Customers TO alice;
GRANT SELECT ON Orders TO alice;

CREATE FUNCTION dbo.customerPredicate(@customer_id INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS result
    WHERE EXISTS (
        SELECT 1
        FROM dbo.Orders o
        WHERE o.customer_id = @customer_id
    )
);
GO

CREATE FUNCTION dbo.ordersPredicate(@customer_id INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS result
    WHERE EXISTS (
        SELECT 1
        FROM dbo.Customers c
        WHERE c.customer_id = @customer_id
    )
);
GO

CREATE SECURITY POLICY customerSecurityPolicy
ADD FILTER PREDICATE dbo.customerPredicate(customer_id)
ON dbo.Customers;
GO

CREATE SECURITY POLICY ordersSecurityPolicy
ADD FILTER PREDICATE dbo.ordersPredicate(customer_id)
ON dbo.Orders;
GO

EXECUTE AS USER = 'alice';
GO

SELECT * FROM Customers;
GO

REVERT;
GO
