# FILE VERSATILE.SH
#
# Create the database versatile with UNICODE encoding and plpyton language support.
# Calls the versatile_create.sql function wich build the database body.
#
PWD_DIR=`dirname $0`
DB_TEMPLATE="template1"
DB_NAME="versatile"
DB_OWNER="postgres"
DB_ADMIN="versatile_admin"; DB_ADMIN_PWD='Ver$@TiL&_@dm!n_pWd'
DB_USER="versatile_user"; DB_USER_PWD='v&rsaT!le_N*t_@dm!n_pWd'
DB_GROUP_USER="versatile_group_users"

SQL_CMD_FILES=`ls ${PWD_DIR}/*.sql`

echo ---------------------------------------- Drop DB ----------------------------------------
dropdb --username ${DB_OWNER} --echo ${DB_NAME} # 2> /dev/null
sleep 1
echo ---------------------------------------- Create DB ----------------------------------------
createdb --username ${DB_OWNER} --encoding UNICODE --template ${DB_TEMPLATE} --echo ${DB_NAME} || exit
createlang --username ${DB_OWNER} --echo plpgsql   ${DB_NAME}
createlang --username ${DB_OWNER} --echo plpythonu ${DB_NAME}
psql --username ${DB_OWNER} --dbname ${DB_NAME} <<CREATEUSER
drop user ${DB_ADMIN};
drop user ${DB_USER};
drop group ${DB_GROUP_USER};
BEGIN;
create user ${DB_ADMIN} with nocreatedb nocreateuser encrypted password '${DB_ADMIN_PWD}';
create user ${DB_USER} with nocreatedb nocreateuser encrypted password '${DB_USER_PWD}';
create group ${DB_GROUP_USER} with USER ${DB_ADMIN}, ${DB_USER};
grant all privileges on schema public to ${DB_ADMIN};
COMMIT;
CREATEUSER
createlang --username ${DB_ADMIN} --list --echo ${DB_NAME}
echo ========================================
for sql_file in ${SQL_CMD_FILES}
do
	echo ---------------------------------------- ${sql_file} ----------------------------------------
	psql --username ${DB_OWNER} --dbname ${DB_NAME} < ${sql_file}
done
