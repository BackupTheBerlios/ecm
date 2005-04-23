-- File VERSATILE_POPULATE.SQL
--
-- Populates the database
-- This means: 
-- * insert into the table entity2id a unique entity number for each table in the database (even if the number is not used)
-- * insert into the table last_use_id the value 0 that is the indeed the last used value, because there are not been insertions yet
-- * insert into every table of interest the table root that will always have id of instance equal to 1!
BEGIN;

INSERT INTO entity2id (id, entity) VALUES (1, 'users');
INSERT INTO last_used_id (entity_id, instance_id) VALUES (1, 0);
INSERT INTO users (description, id, name, pwd) VALUES ('root of table', 1, 'root', 'root_pwd');
INSERT INTO entity2id (id, entity) VALUES (2, 'groups');
INSERT INTO last_used_id (entity_id, instance_id) VALUES (2, 0);
INSERT INTO groups (description, id, name) VALUES ('root of table', 1, 'root');
INSERT INTO entity2id (id, entity) VALUES (3, 'arcs');
INSERT INTO last_used_id (entity_id, instance_id) VALUES (3, 0);
-- INSERT INTO entity2id (id, entity) VALUES (4, 'entity2id');
-- INSERT INTO entity2id (id, entity) VALUES (5, 'free_id');
-- INSERT INTO entity2id (id, entity) VALUES (6, 'last_used_id');
INSERT INTO entity2id (id, entity) VALUES (7, 'permissions');
INSERT INTO last_used_id (entity_id, instance_id) VALUES (7, 0);
INSERT INTO permissions (description, id, name) VALUES ('root of table', 1, 'root');
INSERT INTO entity2id (id, entity) VALUES (8, 'agents');
INSERT INTO last_used_id (entity_id, instance_id) VALUES (8, 0);
--INSERT INTO agents (description, id, ag_type, ag_depth) VALUES ('root of table', 1, 'root', 0);
INSERT INTO entity2id (id, entity) VALUES (9, 'perm_types');
INSERT INTO last_used_id (entity_id, instance_id) VALUES (9, 0);
--INSERT INTO per_types (description, id, perm) VALUES ('root of table', 1, 'root');
INSERT INTO entity2id (id, entity) VALUES (10, 'items');
INSERT INTO last_used_id (entity_id, instance_id) VALUES (10,0);
INSERT INTO items (id, name) VALUES (1, 'root');
--Insertion of elementary permisson types 
INSERT INTO perm_types (description, id, perm) VALUES ('', 10, 'READ');
INSERT INTO perm_types (description, id, perm) VALUES ('', 10, 'WRITE');
INSERT INTO perm_types (description, id, perm) VALUES ('', 10, 'MODIFY');
INSERT INTO perm_types (description, id, perm) VALUES ('', 10, 'DELETE');
INSERT INTO perm_types (description, id, perm) VALUES ('', 10, 'VIEW');
INSERT INTO perm_types (description, id, perm) VALUES ('', 10, 'ADD');
-- Insertion of arcs to explicitate the logical relations among elementary permission types
INSERT INTO arcs VALUES (1, 9, 2, 9, 1);
INSERT INTO arcs VALUES (1, 9, 3, 9, 1);
INSERT INTO arcs VALUES (1, 9, 4, 9, 1);
INSERT INTO arcs VALUES (1, 9, 1, 9, 5);
INSERT INTO arcs VALUES (1, 9, 6, 9, 5);

COMMIT;
