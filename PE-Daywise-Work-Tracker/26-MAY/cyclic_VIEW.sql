CREATE VIEW view_a AS SELECT 1 AS id;
CREATE VIEW view_b AS SELECT 1 AS id;

CREATE OR REPLACE VIEW view_a AS SELECT * FROM view_b;
CREATE OR REPLACE VIEW view_b AS SELECT * FROM view_a;

SELECT * FROM view_a;
-- ERROR: infinite recursion detected in rules for relation "view_a"
