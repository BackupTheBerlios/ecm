-- File VERSATILE_TESTS.SQL
--
-- Tests the  database, with particular attention to the arcs table and the function retrieving the relatives
BEGIN;

SELECT * from groups;

insert into groups (id,name) values (10,'topo');
insert into groups (id,name) values (20,'gigio');
insert into groups (id,name) values (20,'gigio_1');
insert into groups (id,name) values (20,'gigio_2');
insert into groups (id,name) values (20,'gigio_3');
insert into groups (id,name) values (20,'gigio_4');
--delete from groups where id=2;
--delete from groups where name LIKE '%3';
insert into groups (id,name) values (20,'gigio_0');

insert into users (id,name,pwd) values (20,'winnie_2','');
insert into users (id,name,pwd) values (20,'winnie_3','aaa');
insert into users (id,name,pwd) values (20,'winnie_4','');
--delete from users where id<3 and id>1;
insert into users (id,name,pwd) values (20,'winnie_5','');

SELECT * from groups order by id;
SELECT * from users order by id;
--SELECT * from free_id order by entity_id, instance_id;

INSERT INTO permissions (id, name) values (10,'oco_can');

INSERT INTO arcs VALUES (10,2,2,2,3);
INSERT INTO arcs VALUES (10,2,3,2,4);
INSERT INTO arcs VALUES (10,2,4,2,5);
INSERT INTO arcs VALUES (10,2,4,2,6);
INSERT INTO arcs VALUES (10,2,5,2,7);
INSERT INTO arcs VALUES (10,2,6,2,8);
INSERT INTO arcs VALUES (10,2,7,1,2);
INSERT INTO arcs VALUES (10,2,7,1,3);
INSERT INTO arcs VALUES (10,2,8,1,4);
INSERT INTO arcs VALUES (10,2,8,1,5);
INSERT INTO arcs VALUES (10,2,8,1,2);

SELECT * FROM relatives(2,2,0,-1,0,1) AS rel( entity_id integer, instance_id bigint, distance integer) WHERE entity_id=1 ORDER BY distance;
SELECT * FROM relatives(1,2,0,-1,0,0) AS rel( entity_id integer, instance_id bigint, distance integer) WHERE entity_id=2 ORDER BY distance;


COMMIT;