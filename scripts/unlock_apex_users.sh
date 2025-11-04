#!/bin/bash
set -e

echo "🔓 Unlocking APEX users in CDB$ROOT..."

sqlplus / as sysdba <<EOF
-- First unlock in CDB root
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;

-- Then unlock in PDB
ALTER SESSION SET CONTAINER = XEPDB1;
ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;

-- Unlock other APEX users if they exist in PDB
DECLARE
  v_exists NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_exists FROM dba_users WHERE username = 'APEX_REST_PUBLIC_USER';
  IF v_exists > 0 THEN
    EXECUTE IMMEDIATE 'ALTER USER APEX_REST_PUBLIC_USER ACCOUNT UNLOCK';
  END IF;

  SELECT COUNT(*) INTO v_exists FROM dba_users WHERE username = 'APEX_LISTENER';
  IF v_exists > 0 THEN
    EXECUTE IMMEDIATE 'ALTER USER APEX_LISTENER ACCOUNT UNLOCK';
  END IF;
END;
/

EXIT;
EOF

echo "✅ APEX users unlocked!"
