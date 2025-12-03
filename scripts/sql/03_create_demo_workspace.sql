-- Create demo APEX workspace and workspace user
-- Requires: DEMO_WORKSPACE, DEMO_SCHEMA, ORACLE_PWD as substitution variables

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

-- Create workspace
DECLARE
  l_workspace_id NUMBER;
BEGIN
  APEX_UTIL.SET_WORKSPACE('INTERNAL');

  APEX_INSTANCE_ADMIN.ADD_WORKSPACE(
    p_workspace => '&DEMO_WORKSPACE',
    p_primary_schema => '&DEMO_SCHEMA'
  );

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ Workspace created: &DEMO_WORKSPACE');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20987 OR SQLCODE = -20001 THEN
      DBMS_OUTPUT.PUT_LINE('⚠️  Workspace already exists: &DEMO_WORKSPACE');
    ELSE
      DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
      RAISE;
    END IF;
END;
/

-- Create workspace developer user
BEGIN
  APEX_UTIL.SET_WORKSPACE('&DEMO_WORKSPACE');

  APEX_UTIL.CREATE_USER(
    p_user_name => '&DEMO_SCHEMA',
    p_first_name => 'Demo',
    p_last_name => 'Developer',
    p_description => 'Demo workspace developer',
    p_email_address => 'demo@example.com',
    p_web_password => '&ORACLE_PWD',
    p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N'
  );

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ Workspace user created: &DEMO_SCHEMA');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20987 THEN
      DBMS_OUTPUT.PUT_LINE('⚠️  Workspace user already exists: &DEMO_SCHEMA');
    ELSE
      DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
      RAISE;
    END IF;
END;
/
