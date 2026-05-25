CREATE TABLE region (
    r_regionkey INT,
    r_name TEXT,
    r_comment TEXT
);

CREATE TABLE nation (
    n_nationkey INT,
    n_name TEXT,
    n_regionkey INT,
    n_comment TEXT
);

CREATE TABLE supplier (
    s_suppkey INT,
    s_name TEXT,
    s_address TEXT,
    s_nationkey INT,
    s_phone TEXT,
    s_acctbal FLOAT,
    s_comment TEXT
);

CREATE TABLE customer (
    c_custkey INT,
    c_name TEXT,
    c_address TEXT,
    c_nationkey INT,
    c_phone TEXT,
    c_acctbal FLOAT,
    c_mktsegment TEXT,
    c_comment TEXT
);

CREATE TABLE part (
    p_partkey INT,
    p_name TEXT,
    p_mfgr TEXT,
    p_brand TEXT,
    p_type TEXT,
    p_size INT,
    p_container TEXT,
    p_retailprice FLOAT,
    p_comment TEXT
);

CREATE TABLE partsupp (
    ps_partkey INT,
    ps_suppkey INT,
    ps_availqty INT,
    ps_supplycost FLOAT,
    ps_comment TEXT
);

CREATE TABLE orders (
    o_orderkey INT,
    o_custkey INT,
    o_orderstatus TEXT,
    o_totalprice FLOAT,
    o_orderdate DATE,
    o_orderpriority TEXT,
    o_clerk TEXT,
    o_shippriority INT,
    o_comment TEXT
);

CREATE TABLE lineitem (
    l_orderkey INT,
    l_partkey INT,
    l_suppkey INT,
    l_linenumber INT,
    l_quantity FLOAT,
    l_extendedprice FLOAT,
    l_discount FLOAT,
    l_tax FLOAT,
    l_returnflag TEXT,
    l_linestatus TEXT,
    l_shipdate DATE,
    l_commitdate DATE,
    l_receiptdate DATE,
    l_shipinstruct TEXT,
    l_shipmode TEXT,
    l_comment TEXT
);
