-- Unlock APEX system users
-- Requires: None (runs in XEPDB1 container)

ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

BEGIN
  FOR r IN (
    SELECT username
    FROM dba_users
    WHERE username IN ('APEX_PUBLIC_USER', 'APEX_REST_PUBLIC_USER', 'APEX_LISTENER')
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER USER ' || r.username || ' ACCOUNT UNLOCK';
    DBMS_OUTPUT.PUT_LINE('✅ Unlocked: ' || r.username);
  END LOOP;
END;
/
