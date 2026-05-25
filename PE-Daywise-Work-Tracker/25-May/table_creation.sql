-- Create customers table
CREATE TABLE customers (
    id   SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Create orders table
CREATE TABLE orders (
    order_id    SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id)
);

-- Insert 10 customers
INSERT INTO customers (name) VALUES
    ('Aditya Dave'),
    ('Riya Shah'),
    ('Mehul Patel'),
    ('Sneha Joshi'),
    ('Karan Mehta'),
    ('Pooja Iyer'),
    ('Rohan Verma'),
    ('Neha Gupta'),
    ('Arjun Nair'),
    ('Priya Desai');

-- Insert 10 orders
-- Customer 1 (Aditya)  → 3 orders
-- Customer 2 (Riya)    → 2 orders
-- Customer 4 (Sneha)   → 2 orders
-- Customer 6 (Pooja)   → 1 order
-- Customer 8 (Neha)    → 1 order
-- Customer 9 (Arjun)   → 1 order
-- Customers 3,5,7,10   → 0 orders (left out intentionally)
INSERT INTO orders (customer_id) VALUES
    (1),
    (1),
    (1),
    (2),
    (2),
    (4),
    (4),
    (6),
    (8),
    (9);
