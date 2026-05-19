CREATE OR REPLACE FUNCTION orders_predicate(cid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM customers c
WHERE c.customer_id = cid
);
END;
$$;
CREATE FUNCTION


-- Without SECURITY DEFINER:

CREATE OR REPLACE FUNCTION orders_predicate(cid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM customers c
WHERE c.customer_id = cid
);
END;
$$;

-- This will give us inifinte loop





-- This is complete code:

-- =====================================================
-- STEP 1: CLEAN EVERYTHING
-- Remove old policies, functions, role setup
-- =====================================================

DROP POLICY IF EXISTS customer_policy ON customers;
DROP POLICY IF EXISTS orders_policy ON orders;

DROP FUNCTION IF EXISTS customer_predicate(INT);
DROP FUNCTION IF EXISTS orders_predicate(INT);

ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

DROP ROLE IF EXISTS alice;

-- =====================================================
-- STEP 2: CREATE TEST ROLE
-- =====================================================

CREATE ROLE alice LOGIN;

GRANT SELECT ON customers TO alice;
GRANT SELECT ON orders TO alice;

-- =====================================================
-- STEP 3: ENABLE RLS
-- =====================================================

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 4: CREATE UDFs (WITHOUT SECURITY DEFINER)
-- =========================L============================

CREATE OR REPLACE FUNCTION customer_predicate(cid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM orders o
WHERE o.customer_id = cid
);
END;
$$;

CREATE OR REPLACE FUNCTION orders_predicate(cid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM customers c
WHERE c.customer_id = cid
);
END;
$$;

-- =====================================================
-- STEP 5: CREATE CYCLIC RLS POLICIES
-- customers -> orders
-- orders -> customers
-- =====================================================

CREATE POLICY customer_policy
ON customers
FOR SELECT
USING (
customer_predicate(customer_id)
);

CREATE POLICY orders_policy
ON orders
FOR SELECT
USING (
orders_predicate(customer_id)
);

-- =====================================================
-- STEP 6: TEST WITHOUT SECURITY DEFINER
-- EXPECTED: recursion / stack overflow
-- =====================================================

SET ROLE alice;

SELECT * FROM customers;
SELECT * FROM orders;

RESET ROLE;

-- =====================================================
-- STEP 7: REPLACE FUNCTIONS WITH SECURITY DEFINER
-- =====================================================

CREATE OR REPLACE FUNCTION customer_predicate(cid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM orders o
WHERE o.customer_id = cid
);
END;
$$;

CREATE OR REPLACE FUNCTION orders_predicate(cid INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
RETURN EXISTS (
SELECT 1
FROM customers c
WHERE c.customer_id = cid
);
END;
$$;

-- =====================================================
-- STEP 8: TEST WITH SECURITY DEFINER
-- EXPECTED: query succeeds
-- =====================================================

SET ROLE alice;

SELECT * FROM customers;
SELECT * FROM orders;

RESET ROLE;

