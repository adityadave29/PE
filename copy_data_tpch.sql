\copy region FROM '/Users/adityadave/PE/tpc-h/region.tbl' DELIMITER '|' CSV;
\copy nation FROM '/Users/adityadave/PE/tpc-h/nation.tbl' DELIMITER '|' CSV;
\copy supplier FROM '/Users/adityadave/PE/tpc-h/supplier.tbl' DELIMITER '|' CSV;
\copy customer FROM '/Users/adityadave/PE/tpc-h/customer.tbl' DELIMITER '|' CSV;
\copy part FROM '/Users/adityadave/PE/tpc-h/part.tbl' DELIMITER '|' CSV;
\copy partsupp FROM '/Users/adityadave/PE/tpc-h/partsupp.tbl' DELIMITER '|' CSV;
\copy orders FROM '/Users/adityadave/PE/tpc-h/orders.tbl' DELIMITER '|' CSV;
\copy lineitem FROM '/Users/adityadave/PE/tpc-h/lineitem.tbl' DELIMITER '|' CSV;
