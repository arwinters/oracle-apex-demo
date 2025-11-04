-- Create demo APEX workspace
-- Requires: DEMO_WORKSPACE, DEMO_SCHEMA as substitution variables

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

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
