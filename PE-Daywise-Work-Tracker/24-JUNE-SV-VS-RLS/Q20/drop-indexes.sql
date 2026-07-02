-- ============================================================
-- Remove all benchmark indexes
-- ============================================================

DROP INDEX IF EXISTS idx_lineitem_partkey_suppkey_shipdate;
DROP INDEX IF EXISTS idx_lineitem_orderkey;
DROP INDEX IF EXISTS idx_orders_orderkey_priority;
DROP INDEX IF EXISTS idx_partsupp_partkey_suppkey_availqty;
DROP INDEX IF EXISTS idx_partsupp_suppkey;
DROP INDEX IF EXISTS idx_supplier_nationkey;
DROP INDEX IF EXISTS idx_nation_regionkey;
DROP INDEX IF EXISTS idx_part_name_trgm;

-- Optional: remove the extension if it was created only for this benchmark
DROP EXTENSION IF EXISTS pg_trgm;