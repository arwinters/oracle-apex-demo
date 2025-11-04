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

-- Enable REST access via ORDS
BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(
    p_enabled => TRUE,
    p_schema  => '&DEMO_SCHEMA',
    p_url_mapping_type => 'BASE_PATH',
    p_url_mapping_pattern => LOWER('&DEMO_SCHEMA'),
    p_auto_rest_auth => TRUE
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ REST enabled for schema: &DEMO_SCHEMA');
END;
/
