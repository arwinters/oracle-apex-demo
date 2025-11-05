-- Create demo schema and enable REST access via ORDS
-- Requires: DEMO_SCHEMA, ORACLE_PWD as substitution variables

WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = XEPDB1;

-- Create schema if not exists
BEGIN
  EXECUTE IMMEDIATE 'CREATE USER &DEMO_SCHEMA IDENTIFIED BY &ORACLE_PWD';
  DBMS_OUTPUT.PUT_LINE('✅ Created schema: &DEMO_SCHEMA');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -01920 THEN
      DBMS_OUTPUT.PUT_LINE('⚠️  Schema already exists: &DEMO_SCHEMA');
    ELSE
      RAISE;
    END IF;
END;
/

-- Grant privileges
GRANT CONNECT, RESOURCE TO &DEMO_SCHEMA;
ALTER USER &DEMO_SCHEMA QUOTA UNLIMITED ON USERS;

-- Note: REST enablement happens AFTER ORDS registration (see 06_enable_rest_schema.sql)
