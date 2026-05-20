CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE customers_plain (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(id)
);

CREATE TABLE orders_plain (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers_plain(id)
);












INSERT INTO customers (id, name) VALUES
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

INSERT INTO customers_plain (id, name) VALUES
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



INSERT INTO orders (order_id, customer_id) VALUES
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

INSERT INTO orders_plain (order_id, customer_id) VALUES
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











-- Policy logic (reference)

-- Customers table policy:
-- A role can see a customer row only if that customer’s id exists as customer_id in the orders table.

-- Orders table policy:
-- A role can see an order row only if that order’s customer_id exists as id in the customers table.



ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION check_customer_access(custid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.customer_id = custid
    );
END;
$$;

CREATE OR REPLACE FUNCTION check_order_access(custid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM customers c
        WHERE c.id = custid
    );
END;
$$;

REVOKE ALL ON FUNCTION check_customer_access(INT) FROM PUBLIC;
REVOKE ALL ON FUNCTION check_order_access(INT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION check_customer_access(INT) TO alice;
GRANT EXECUTE ON FUNCTION check_order_access(INT) TO alice;

CREATE POLICY customer_policy
ON customers
FOR SELECT
USING (
    check_customer_access(id)
);

CREATE POLICY order_policy
ON orders
FOR SELECT
USING (
    check_order_access(customer_id)
);


testing=> SELECT * FROM customers;
  1 | Alice
  2 | Bob
  3 | Carol
  5 | Eve
  7 | Grace
  8 | Hank
 10 | Jack

GRANT SELECT ON customers TO alice;
GRANT SELECT ON orders TO alice;

testing=> SELECT * from customers_plain;
  1 | Alice
  2 | Bob
  3 | Carol
  4 | David
  5 | Eve
  6 | Frank
  7 | Grace
  8 | Hank
  9 | Ivy
 10 | Jack

