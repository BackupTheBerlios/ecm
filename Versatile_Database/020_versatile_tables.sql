-- File VERSATILE_TABLES.SQL
--
-- Creates the tables necessary to manage the versatile database and other tables 
--	for the management of the permissions and for testing purpose

BEGIN;

-- --------------------------------------------------------------------------
--	DESCRIPTION
-- --------------------------------------------------------------------------
create table description (
	description			varchar(200)
	);
-- --------------------------------------------------------------------------
--	USERS
-- --------------------------------------------------------------------------
CREATE TABLE users (
	id 				bigint 				PRIMARY KEY default 0,
	name 				varchar(60) 			NOT NULL UNIQUE,
	pwd 				varchar(60) 			NOT NULL
	)
	inherits (description);
CREATE INDEX users_name_idx ON users(name);
CREATE TRIGGER users_b_insert BEFORE INSERT on users FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER users_a_insert AFTER  INSERT on users FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER users_a_delete AFTER  DELETE on users FOR EACH ROW EXECUTE PROCEDURE delete_row_from_table();
-- --------------------------------------------------------------------------
--  GROUPS
-- --------------------------------------------------------------------------
CREATE TABLE groups (
	id				bigint				PRIMARY KEY default 0,
	name				varchar(500)			NOT NULL UNIQUE
	)
	inherits (description);
CREATE INDEX groups_name_idx ON groups(name);
CREATE TRIGGER groups_b_insert BEFORE INSERT on groups FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER groups_a_insert AFTER  INSERT on groups FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER groups_a_delete AFTER  DELETE on groups FOR EACH ROW EXECUTE PROCEDURE delete_row_from_table();
-- --------------------------------------------------------------------------
--  TABLES <-> ID
-- --------------------------------------------------------------------------
CREATE TABLE entity2id (
	id 				integer				PRIMARY KEY,
	entity				varchar(40)			NOT NULL UNIQUE
	)
	inherits (description);
CREATE INDEX entity2id_entity ON entity2id(entity);
-- --------------------------------------------------------------------------
--  FREE IDs for insertion in Entities
-- --------------------------------------------------------------------------
CREATE TABLE free_id (
	entity_id			integer				NOT NULL references entity2id(id),
	instance_id			bigint				NOT NULL,
	PRIMARY KEY (instance_id, entity_id)
	)
	inherits (description);
CREATE INDEX free_id_entity_idx ON free_id(entity_id);
CREATE INDEX free_id_instance_idx ON free_id(instance_id);
-- --------------------------------------------------------------------------
--  ARCS: relations among different nodes
-- --------------------------------------------------------------------------
CREATE TABLE arcs (
	id				integer,
	src_entity_id			integer				NOT NULL references entity2id(id),
	src_instance_id			bigint				NOT NULL,
	dst_entity_id			integer				NOT NULL references entity2id(id),
	dst_instance_id			bigint				NOT NULL,
	PRIMARY KEY (id, src_entity_id, src_instance_id, dst_entity_id, dst_instance_id),
	CONSTRAINT diff_nodes CHECK ( (src_entity_id,src_instance_id) <> (dst_entity_id,dst_instance_id) )
	);
CREATE INDEX arcs_s_entity_idx   ON arcs(src_entity_id);
CREATE INDEX arcs_s_instance_idx ON arcs(src_instance_id);
CREATE INDEX arcs_d_entity_idx   ON arcs(dst_entity_id);
CREATE INDEX arcs_d_instance_idx ON arcs(dst_instance_id);
CREATE TRIGGER arcs_b_insert_a BEFORE INSERT ON arcs FOR EACH ROW EXECUTE PROCEDURE insert_row_into_arcs();
CREATE TRIGGER arcs_b_insert BEFORE INSERT ON arcs FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER arcs_a_insert_a AFTER INSERT ON arcs FOR EACH ROW EXECUTE PROCEDURE insert_row_into_arcs();
CREATE TRIGGER arcs_a_insert AFTER  INSERT ON arcs FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER arcs_a_delete AFTER  DELETE ON arcs FOR EACH ROW EXECUTE PROCEDURE delete_row_from_table();
-- --------------------------------------------------------------------------
-- permissions
-- --------------------------------------------------------------------------
create table permissions (
	id				bigint				PRIMARY KEY default 0,
	name				varchar(30)			NOT NULL UNIQUE
	)
	inherits (description);
CREATE TRIGGER permissions_b_insert BEFORE INSERT on permissions FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER permissions_a_insert AFTER  INSERT on permissions FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER permissions_a_delete AFTER  DELETE on permissions FOR EACH ROW EXECUTE PROCEDURE delete_row_from_table();
-- --------------------------------------------------------------------------
-- AGENTS
-- --------------------------------------------------------------------------
create table agents (
	id				bigint				PRIMARY KEY,
	ag_type				varchar(30)			not null,
	ag_depth			integer				not null-- This define the scope of the agent's parent in a spatial manner
	)
	inherits (description);
CREATE INDEX agent_idx ON agents(ag_type, ag_depth);
CREATE TRIGGER agents_b_insert BEFORE INSERT on agents FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER agents_a_insert AFTER  INSERT on agents FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER agents_a_delete AFTER  DELETE on agents FOR EACH ROW EXECUTE PROCEDURE delete_row_from_table();
-- --------------------------------------------------------------------------
-- PERM_TYPES
-- --------------------------------------------------------------------------
create table perm_types (
	id				bigint				PRIMARY KEY,
	perm				varchar(30)			NOT NULL UNIQUE
	)
	inherits (description);
CREATE TRIGGER perm_types_b_insert BEFORE INSERT on perm_types FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER perm_types_a_insert AFTER  INSERT on perm_types FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER perm_types_a_delete AFTER  DELETE on perm_types FOR EACH ROW EXECUTE PROCEDURE delete_row_from_table();	

-- --------------------------------------------------------------------------
-- ITEMS
-- --------------------------------------------------------------------------
-- This table is created for testing purpose and is used only to test the insertion and query times 
CREATE TABLE items (
	id				bigint				PRIMARY KEY,
	name				varchar(300)		NOT NULL UNIQUE
	);
CREATE TRIGGER items_b_insert BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER items_a_insert AFTER  INSERT ON items FOR EACH ROW EXECUTE PROCEDURE insert_row_into_table();
CREATE TRIGGER items_a_delete AFTER  DELETE ON items FOR EACH ROW EXECUTE PROCEDURE delete_row_from_table();

-- --------------------------------------------------------------------------
-- LAST_USED_ID
-- --------------------------------------------------------------------------
-- This table is necessary to retrieve the IDs of the just inserted instances, because such IDs are given automatically by the database
create table last_used_id (
	entity_id			integer				not null,
	instance_id			bigint				not null,
	primary key (instance_id, entity_id)
	);
create index last_used_id_entity_idx on last_used_id(entity_id);
create index last_used_id_instance_idx on last_used_id(instance_id);
grant select,update on last_used_id to group versatile_group_users;

COMMIT;
