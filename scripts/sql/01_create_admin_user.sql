-- Create APEX admin user for INTERNAL workspace
-- Requires: APEX_ADMIN_USER, APEX_ADMIN_EMAIL, APEX_ADMIN_PASSWORD as substitution variables

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

BEGIN
  APEX_UTIL.SET_WORKSPACE('INTERNAL');

  APEX_UTIL.CREATE_USER(
    p_user_name => '&APEX_ADMIN_USER',
    p_first_name => 'Admin',
    p_last_name => 'User',
    p_description => 'Administrator',
    p_email_address => '&APEX_ADMIN_EMAIL',
    p_web_password => '&APEX_ADMIN_PASSWORD',
    p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N'
  );

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ APEX admin user created: &APEX_ADMIN_USER');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20987 THEN
      DBMS_OUTPUT.PUT_LINE('⚠️  Admin user already exists: &APEX_ADMIN_USER');
    ELSE
      DBMS_OUTPUT.PUT_LINE('❌ Error: ' || SQLERRM);
      RAISE;
    END IF;
END;
/
