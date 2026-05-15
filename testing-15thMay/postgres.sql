-- create database
CREATE DATABASE testing;

-- switch to testing database
\c testing

-- create tables
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name TEXT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT
);

-- add data into it
INSERT INTO customers VALUES
(1, 'Alice'),
(2, 'Bob');

INSERT INTO orders VALUES
(101, 1),
(102, 2);

-- Enable row level security
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- create policy 1
CREATE POLICY customer_policy
ON customers
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.customer_id = customers.customer_id
    )
);


-- create policy 2
CREATE POLICY orders_policy
ON orders
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM customers c
        WHERE c.customer_id = orders.customer_id
    )
);

--create role for testing
CREATE ROLE alice LOGIN PASSWORD 'alice123';

-- give access to that role
GRANT SELECT ON customers TO alice;
GRANT SELECT ON orders TO alice;

-- set role
SET ROLE alice;

-- final execution of query
SELECT * FROM customers;

--expected output:
ERROR:  infinite recursion detected in policy for relation "customers"
