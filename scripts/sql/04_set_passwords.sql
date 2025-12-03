-- Set passwords for APEX system users
-- Requires: ORACLE_PWD as substitution variable

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

BEGIN
  FOR r IN (
    SELECT username
    FROM dba_users
    WHERE username IN ('APEX_PUBLIC_USER', 'APEX_REST_PUBLIC_USER', 'APEX_LISTENER')
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER USER ' || r.username || ' IDENTIFIED BY &ORACLE_PWD';
    DBMS_OUTPUT.PUT_LINE('✅ Password set for: ' || r.username);
  END LOOP;
END;
/
