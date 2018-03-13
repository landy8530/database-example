CREATE OR REPLACE FUNCTION "GET_DATABASE_NAME"
return varchar2
AUTHID CURRENT_USER AS
/*
 * Castro version: 3
 */

vDatabaseName    v$parameter.value%TYPE := NULL;
vSelectStatement varchar2(200)          := NULL;

BEGIN


    vSelectStatement := 'SELECT upper(value) ' || ' ' ||
                            'FROM   v$parameter'   || ' ' ||
                            'WHERE  lower(name) =' || '''' || 'db_name' || '''';

    EXECUTE IMMEDIATE vSelectStatement INTO vDatabaseName;

    return vDatabaseName;

    EXCEPTION

     WHEN others then

         RAISE_APPLICATION_ERROR(-20000,'The database version is not recognized.');

END;