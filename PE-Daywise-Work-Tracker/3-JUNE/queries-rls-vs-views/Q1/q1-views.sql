-- Step 1: Disable RLS on lineitem
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing view if any
DROP VIEW IF EXISTS lineitem_secure;

-- Step 3: Create view with same filter logic as RLS policy
CREATE VIEW lineitem_secure AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1 FROM supplier s
    WHERE s.s_suppkey = l.l_suppkey
    AND s.s_acctbal > 1000
);

-- Step 4: Grant permissions
GRANT SELECT ON lineitem_secure TO current_user;

-- Step 5: Run Q1 with timing
\timing on
EXPLAIN (ANALYZE, VERBOSE, BUFFERS)
select
    l_returnflag,
    l_linestatus,
    sum(l_quantity) as sum_qty,
    sum(l_extendedprice) as sum_base_price,
    sum(l_extendedprice * (1 - l_discount)) as sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge,
    avg(l_quantity) as avg_qty,
    avg(l_extendedprice) as avg_price,
    avg(l_discount) as avg_disc,
    count(*) as count_order
from
    lineitem_secure
where
    l_shipdate <= date '1998-12-01' - interval '3' day
group by
    l_returnflag,
    l_linestatus
order by
    l_returnflag,
    l_linestatus;





-- ============================================================
-- SHARED SETUP: Drop everything clean before starting
-- ============================================================

DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
    END LOOP;
END;
$$;

ALTER TABLE lineitem  DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders    DISABLE ROW LEVEL SECURITY;
ALTER TABLE customer  DISABLE ROW LEVEL SECURITY;
ALTER TABLE supplier  DISABLE ROW LEVEL SECURITY;
ALTER TABLE part      DISABLE ROW LEVEL SECURITY;
ALTER TABLE partsupp  DISABLE ROW LEVEL SECURITY;
ALTER TABLE nation    DISABLE ROW LEVEL SECURITY;
ALTER TABLE region    DISABLE ROW LEVEL SECURITY;

DROP VIEW IF EXISTS lineitem_view_plain;
DROP VIEW IF EXISTS lineitem_view_barrier;


-- ============================================================
-- VARIANT 1: RLS
-- ============================================================

ALTER TABLE lineitem ENABLE ROW LEVEL SECURITY;

CREATE POLICY lineitem_supplier_policy ON lineitem
USING (
    EXISTS (
        SELECT 1 FROM supplier s
        WHERE s.s_suppkey = lineitem.l_suppkey
          AND s.s_acctbal > 1000
    )
);

-- Force RLS to apply even to table owner (optional but recommended for fair testing)
ALTER TABLE lineitem FORCE ROW LEVEL SECURITY;

\timing on

EXPLAIN (ANALYZE, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT
    l_returnflag,
    l_linestatus,
    sum(l_quantity)                                       AS sum_qty,
    sum(l_extendedprice)                                  AS sum_base_price,
    sum(l_extendedprice * (1 - l_discount))               AS sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
    avg(l_quantity)                                       AS avg_qty,
    avg(l_extendedprice)                                  AS avg_price,
    avg(l_discount)                                       AS avg_disc,
    count(*)                                              AS count_order
FROM lineitem
WHERE l_shipdate <= date '1998-12-01' - interval '3' day
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;

\timing off

-- Teardown RLS before next variant
ALTER TABLE lineitem NO FORCE ROW LEVEL SECURITY;
ALTER TABLE lineitem DISABLE ROW LEVEL SECURITY;

DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT policyname, tablename FROM pg_policies WHERE schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
    END LOOP;
END;
$$;


-- ============================================================
-- VARIANT 2: Plain VIEW (no security_barrier)
-- ============================================================

CREATE VIEW lineitem_view_plain AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1 FROM supplier s
    WHERE s.s_suppkey = l.l_suppkey
      AND s.s_acctbal > 1000
);

\timing on

EXPLAIN (ANALYZE, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT
    l_returnflag,
    l_linestatus,
    sum(l_quantity)                                       AS sum_qty,
    sum(l_extendedprice)                                  AS sum_base_price,
    sum(l_extendedprice * (1 - l_discount))               AS sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
    avg(l_quantity)                                       AS avg_qty,
    avg(l_extendedprice)                                  AS avg_price,
    avg(l_discount)                                       AS avg_disc,
    count(*)                                              AS count_order
FROM lineitem_view_plain
WHERE l_shipdate <= date '1998-12-01' - interval '3' day
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;


DROP VIEW IF EXISTS lineitem_view_plain;


-- ============================================================
-- VARIANT 3: security_barrier VIEW
-- ============================================================

CREATE VIEW lineitem_view_barrier
WITH (security_barrier = true) AS
SELECT l.*
FROM lineitem l
WHERE EXISTS (
    SELECT 1 FROM supplier s
    WHERE s.s_suppkey = l.l_suppkey
      AND s.s_acctbal > 1000
);


EXPLAIN (ANALYZE, VERBOSE, BUFFERS, FORMAT TEXT)
SELECT
    l_returnflag,
    l_linestatus,
    sum(l_quantity)                                       AS sum_qty,
    sum(l_extendedprice)                                  AS sum_base_price,
    sum(l_extendedprice * (1 - l_discount))               AS sum_disc_price,
    sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) AS sum_charge,
    avg(l_quantity)                                       AS avg_qty,
    avg(l_extendedprice)                                  AS avg_price,
    avg(l_discount)                                       AS avg_disc,
    count(*)                                              AS count_order
FROM lineitem_view_barrier
WHERE l_shipdate <= date '1998-12-01' - interval '3' day
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;
