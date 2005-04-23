-- File VERSATILE_FUNCTIONS.SQL
--
-- Creates the functions, realized in PLPgSQL, necessary to bypass the DBMS and realize a versatile, but stable database 

BEGIN;

-- Entity -> ID
CREATE OR REPLACE FUNCTION get_entity_id_from_table_name(text) RETURNS integer AS '
	DECLARE
	rv integer;
	name alias for $1;
	
	BEGIN
	SELECT INTO rv id FROM entity2id WHERE entity = name;
	IF rv > 0 THEN
		RETURN rv;
	ELSE
		RAISE EXCEPTION ''No such table ''''%'''''', name;
		RETURN;
	END IF;
	END
'LANGUAGE plpgsql;

-- system OID -> entity name
CREATE OR REPLACE FUNCTION get_entity_name_from_system_oid(bigint) RETURNS text AS '
	DECLARE
	rv text;
	BEGIN
	SELECT INTO rv relname FROM pg_class WHERE oid=$1;
	RETURN rv;
	END
'LANGUAGE plpgsql;

-- system OID -> entity ID
CREATE OR REPLACE FUNCTION get_entity_id_from_system_oid(bigint) RETURNS integer AS'
	DECLARE
	rv integer;
	BEGIN
	SELECT INTO rv id FROM entity2id WHERE entity=(SELECT relname FROM pg_class where oid=$1);
	RETURN rv;
	END
'LANGUAGE plpgsql;

-- table name -> lowest free id avalable (removes it from list before returning)
CREATE OR REPLACE FUNCTION use_free_id_for_table(text) RETURNS bigint AS'
	DECLARE
	__DEBUG CONSTANT INTEGER :=0;
	e_id integer;
	rv_min BIGINT;
	rv_max BIGINT;
	BEGIN
	SELECT INTO e_id id FROM entity2id WHERE entity=$1;
	SELECT INTO rv_min min(instance_id) FROM free_id WHERE entity_id= e_id;
	IF __DEBUG THEN RAISE NOTICE ''rv_min = %'',rv_min;END IF;
	SELECT INTO rv_max max(instance_id) FROM free_id WHERE entity_id= e_id;
	IF __DEBUG = 1 THEN RAISE NOTICE ''rv_max = %'',rv_max;END IF;
	IF rv_min IS NULL THEN
		INSERT INTO free_id (entity_id, instance_id) VALUES (e_id, 2);
		IF __DEBUG = 1 THEN RAISE NOTICE ''inserito il valore 2 nella tabella free_id'';END IF;
		RETURN 1;
	ELSE
		DELETE FROM free_id WHERE entity_id = e_id AND instance_id = rv_min;
		IF rv_min = rv_max THEN
			INSERT INTO free_id (entity_id, instance_id) VALUES (e_id, rv_min+1% );
		END IF;
		RETURN rv_min;
	END IF;
	END
'LANGUAGE plpgsql;

-- trigger: called before insert: assign row 'id' to 0
--			called after insert: assign row 'id' to lowest free value
--	(validity checks are done by DB constraints)
--DROP FUNCTION insert_row_into_table();
CREATE OR REPLACE FUNCTION insert_row_into_table() RETURNS trigger AS'
	DECLARE
	__DEBUG CONSTANT INTEGER :=0;
	table_name text;
	new_id bigint;
	entity_id integer;
	str text;
	lock_str text;
	BEGIN
	IF __DEBUG THEN RAISE NOTICE ''Value in NEW.id --> %'',NEW.id; END IF;
	IF TG_WHEN = ''BEFORE'' THEN
		NEW.id=0;
		IF __DEBUG THEN RAISE NOTICE ''Executed BEFORE trigger!''; END IF;
		RETURN NEW;
	ELSIF TG_WHEN =''AFTER'' THEN
		IF __DEBUG THEN RAISE NOTICE ''Value in NEW.id --> %'',NEW.id; END IF;
		table_name=TG_RELNAME; -- ATTENZIONE QUA!!!!
		IF __DEBUG THEN RAISE NOTICE ''Value in table_name --> %'',table_name; END IF;
		SELECT INTO new_id use_free_id_for_table(table_name);
		IF __DEBUG THEN RAISE NOTICE ''Value in new_id --> %'',new_id; END IF;
		IF NOT(new_id IS NULL)THEN
			str = ''UPDATE ''|| table_name||'' SET id=''||new_id||'' WHERE id=''|| NEW.id;
			EXECUTE str;
			NEW.id=new_id;
			SELECT INTO entity_id id FROM entity2id WHERE entity = table_name;
			lock_str = ''SELECT * FROM last_used_id WHERE entity_id =''||entity_id||''FOR UPDATE OF last_used_id'';
			EXECUTE lock_str;
			str = ''UPDATE last_used_id SET instance_id=''||new_id||'' WHERE entity_id=''||entity_id;
			EXECUTE str;
			RETURN NEW;
		ELSE
			RAISE EXCEPTION ''No free id for table ''''%'''''', table_name;
		END IF;
	ELSE
		RAISE EXCEPTION ''UNHANDLED call!'';
	END IF;
	END
'LANGUAGE plpgsql;

-- trigger: called after delete: saves row 'id' into free_id and eliminates every arc connected to the deleted instance
--	(validity checks are done by DB constraints)
CREATE OR REPLACE FUNCTION delete_row_from_table() RETURNS trigger AS'
	DECLARE
	__DEBUG CONSTANT INTEGER :=0;
	table_name text;
	entity_id integer;
	str text;
	BEGIN
	IF TG_WHEN = ''AFTER''THEN
		table_name=TG_RELNAME;
		SELECT INTO entity_id get_entity_id_from_table_name(table_name);
		str = ''INSERT INTO free_id (entity_id,instance_id) VALUES ( ''||entity_id||'', ''||OLD.id||'')'';
		IF __DEBUG THEN RAISE NOTICE ''FUNCTION DELETE_ROW_FROM_TABLE: Value in str --> %'',str; END IF;
		EXECUTE str;
		str = ''DELETE FROM arcs WHERE (src_entity_id=''||entity_id||'' AND src_instance_id=''||OLD.id||'') OR (dst_entity_id=''||entity_id||'' AND dst_instance_id=''||OLD.id||'')'';
		EXECUTE str;
		RETURN OLD;
	ELSE
		RAISE EXCEPTION ''UNHANDLED call!'';
	END IF;
	END
'LANGUAGE plpgsql;

-- Returns all the relatives of a certainc kind within the wanted recursion level
-- When called with a valid value of recursion level the function returns the current node only if there are relatives of the desired kind
-- Uses the function get_arcs to extract the adjacent relatives
CREATE OR REPLACE FUNCTION relatives(integer, bigint, integer, integer, integer, integer) RETURNS SETOF RECORD AS '	
	DECLARE
	_row RECORD;				-- is the record the function returns. It has 3 fields: entity_id, instance_id and distance
	_entity_id ALIAS FOR $1;
	_instance_id ALIAS FOR $2;
	_family ALIAS FOR $3;			-- family of the relatives to return: 0= every family; -1= every family except starting node''s one
	_recurs_lev integer;			-- 0: only this node; -1: recursion infinite; > 0: n recursions; < -1: Invalid entry  
	_actual_lev ALIAS FOR $5;
	_kind_of_relatives ALIAS FOR $6;	-- 0=parents; 1=children


	BEGIN
	_recurs_lev = $4;
	
	IF _recurs_lev < -1 THEN
		RAISE EXCEPTION ''Invalid number of recursion depth --> % in function relatives'', _recurs_lev;
		RETURN;
	ELSIF _recurs_lev = 0 THEN
		IF _actual_lev =0 THEN
			SELECT INTO _row  _entity_id AS entity_id,_instance_id AS instance_id, _actual_lev AS lev
			FROM get_arcs(_entity_id, _instance_id, _family, _kind_of_relatives) AS doms(next_entity_id integer, next_instance_id bigint)
			ORDER BY next_entity_id, next_instance_id;
			RETURN NEXT _row;
		END IF;
		RETURN;
	ELSIF _recurs_lev > 0 THEN
		_recurs_lev = _recurs_lev -1;
	END IF;
	-- Con _recurs_lev = -1 non devo eseguire operazioni sulla variabile --> non tratto il caso e continuo
	
	IF _actual_lev =0 THEN
		SELECT INTO _row  _entity_id AS entity_id,_instance_id AS instance_id, _actual_lev AS lev
		FROM get_arcs(_entity_id, _instance_id, _family, _kind_of_relatives) AS doms(next_entity_id integer, next_instance_id bigint)
		ORDER BY next_entity_id, next_instance_id;
		RETURN NEXT _row;
	END IF;
	
	FOR _row IN 
	SELECT next_entity_id AS entity_id,next_instance_id AS instance_id, _actual_lev +1 AS lev
	FROM get_arcs(_entity_id, _instance_id, _family, _kind_of_relatives) AS doms(next_entity_id integer, next_instance_id bigint)
	ORDER BY next_entity_id, next_instance_id
	LOOP
		RETURN NEXT _row;
		FOR _row IN 
		SELECT * 
		FROM relatives(_row.entity_id, _row.instance_id, _family, _recurs_lev, _row.lev, _kind_of_relatives) AS relatives(entity_id integer, instance_id bigint, distance integer)
		ORDER BY entity_id, instance_id
		LOOP
			RETURN NEXT _row;
		END LOOP;
	END LOOP;
	RETURN;
	
	END
' LANGUAGE plpgsql;
-- --------------------------------------------------------------------------
-- trigger called before inserting a row into the arcs table:
-- 	it verifyes that the arc it is going to be inserted does not introduce a cycle into the structure
--trigger called after inserting a row into the arcs table:
--	it verifyes that the instances are going to be connected exist
--	(Validity checks are done by the db constraints)
CREATE OR REPLACE FUNCTION insert_row_into_arcs() RETURNS trigger AS'
	DECLARE
	__DEBUG CONSTANT INTEGER :=0;
	src_entity 		varchar;
	dst_entity 		varchar;
	src_inst_id 	integer;
	dst_inst_id 	integer;
	sql				varchar;
	refc			refcursor;
	_row			record;
	BEGIN
	IF TG_WHEN = ''BEFORE'' THEN
		sql=''SELECT * FROM relatives(''||NEW.src_entity_id||'',''||NEW.src_instance_id||'',0,-1,0,0) AS rel(e_id integer, i_id bigint, dist integer) WHERE e_id=''||NEW.dst_entity_id|| '' AND i_id = ''||NEW.dst_instance_id;
		IF __DEBUG THEN RAISE NOTICE ''TRIGGER INSERT_ROW_INTO_ARCS: sql --> %'',sql; END IF;
		OPEN refc FOR EXECUTE sql;
		FETCH refc INTO _row;
		CLOSE refc;
		IF __DEBUG THEN RAISE NOTICE ''Value in _row.i_id --> %'',_row.i_id; END IF;
		IF _row.i_id IS NULL THEN
			RETURN NEW;
		ELSE
			RAISE EXCEPTION ''Attempted to create a cycle'';
			RETURN NULL;
		END IF;
	ELSIF TG_WHEN = ''AFTER'' THEN	
		SELECT INTO src_entity entity FROM entity2id WHERE id=NEW.src_entity_id;
		IF __DEBUG THEN RAISE NOTICE ''Value in src_entity --> %'',src_entity; END IF;
		SELECT INTO dst_entity entity FROM entity2id WHERE id=NEW.dst_entity_id;
		IF __DEBUG THEN RAISE NOTICE ''Value in dst_entity --> %'',dst_entity; END IF;
		sql=''SELECT id FROM '' || quote_ident(src_entity)||'' WHERE id=''||NEW.src_instance_id;
		OPEN refc FOR EXECUTE sql;
		FETCH refc INTO src_inst_id;
		CLOSE refc;
		IF __DEBUG THEN RAISE NOTICE ''Value in src_inst_id --> %'',src_inst_id; END IF;
		sql=''SELECT id FROM '' || quote_ident(dst_entity)||'' WHERE id=''||NEW.dst_instance_id;
		OPEN refc FOR EXECUTE sql;
		FETCH refc INTO dst_inst_id;
		CLOSE refc;
		IF __DEBUG THEN RAISE NOTICE ''Value in dst_inst_id --> %'',dst_inst_id; END IF;
		IF (src_inst_id IS NULL) OR (dst_inst_id IS NULL) THEN
			RAISE EXCEPTION ''Attempted to create an inconsistent arc'';
			RETURN NULL;
		ELSE	
			RETURN NEW;
		END IF;
	ELSE
		RAISE EXCEPTION ''Unhandled trigger when!'';
	END IF;
	END
'LANGUAGE plpgsql;
-- Given entity_id,  instance_id and kind of relatives this function returns all the relatives of the desired kind
--	adjacent to the given one extracting them from the arcs table
CREATE OR REPLACE FUNCTION get_arcs(integer, bigint, integer, integer) RETURNS SETOF RECORD AS '
	DECLARE
	__DEBUG CONSTANT 		INTEGER :=0;
	_row 					RECORD;		-- is the record the function returns. It has 2 fields: next_entity_id and next_instance_id
	_entity_id ALIAS FOR $1;
	_instance_id ALIAS FOR $2;
	_family ALIAS FOR $3;				-- family of the relatives to return: 0= every family; >0:= family type 
	_kind_of_relatives ALIAS FOR $4;	-- 0=parents; 1=children
	_cond_on_family			varchar;
	query					varchar;
	rfcur					refcursor;
	
	BEGIN
	--this is for the parents
	IF _kind_of_relatives = 0 THEN
		IF _family = 0 THEN
			_cond_on_family='''';
		ELSIF _family < 0 THEN
			RAISE EXCEPTION ''Illegal family type'';
		ELSE
			_cond_on_family='' AND src_entity_id='' ||_family;
		END IF;
		query=''SELECT src_entity_id AS e_id , src_instance_id AS i_id  FROM arcs WHERE dst_entity_id = ''||_entity_id||'' AND dst_instance_id = ''||_instance_id||'' ''||_cond_on_family;
	--this is for the children
	ELSE
		IF _family = 0 THEN
			_cond_on_family='''';
		ELSIF _family < 0 THEN
			RAISE EXCEPTION ''Illegal family type'';
			RETURN;
		ELSE
			_cond_on_family='' AND dst_entity_id=''|| _family;
		END IF;
		query=''SELECT dst_entity_id AS e_id , dst_instance_id AS i_id  FROM arcs WHERE src_entity_id = ''||_entity_id||'' AND src_instance_id = ''||_instance_id||'' ''||_cond_on_family;
	END IF;
	IF __DEBUG THEN RAISE NOTICE ''Value in query --> %'',query; END IF;
	OPEN rfcur FOR EXECUTE query;
	LOOP
		FETCH rfcur INTO _row;
		EXIT WHEN NOT FOUND;
		RETURN NEXT _row;
	END LOOP;
	IF __DEBUG THEN RAISE NOTICE ''Exit from while loop''; END IF;
	CLOSE rfcur;
	RETURN;
	END
' LANGUAGE plpgsql;
-- --------------------------------------------------------------------------
COMMIT;
