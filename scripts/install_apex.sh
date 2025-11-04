#!/bin/bash
set -e

echo "🔍 Checking APEX installation files..."
if [ ! -f "/opt/oracle/apex/apexins.sql" ]; then
  echo "📦 Downloading Oracle APEX 24.2..."
  cd /opt/oracle
  curl -s -o apex_24.2.zip https://download.oracle.com/otn_software/apex/apex_24.2.zip
  unzip -q apex_24.2.zip && rm apex_24.2.zip

  # Move content up one level if nested directory exists
  if [ -d "/opt/oracle/apex/apex" ]; then
    echo "📂 Moving APEX files up one level..."
    mv /opt/oracle/apex/apex/* /opt/oracle/apex/
    rmdir /opt/oracle/apex/apex
  fi

  echo "✅ APEX 24.2 downloaded and extracted."
else
  echo "✅ APEX installation files found."
fi

echo "⏳ Waiting for Oracle Database to be ready..."
sleep 10

echo "🧠 Checking if APEX is already installed..."
if sqlplus -s / as sysdba <<EOF | grep -q "APEX_240200"
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT username FROM dba_users WHERE username LIKE 'APEX_%';
EXIT;
EOF
then
  echo "⚠️  APEX already installed, skipping reinstallation."
else
  echo "🚀 Starting APEX installation..."
  cd /opt/oracle/apex
  sqlplus -s / as sysdba <<EOF
  WHENEVER SQLERROR EXIT SQL.SQLCODE
  ALTER SESSION SET CONTAINER = XEPDB1;
  @apexins.sql SYSAUX SYSAUX TEMP /i/
EOF
fi

echo "🔐 Setting APEX admin user for APEX 24.2..."
sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

BEGIN
  APEX_UTIL.SET_WORKSPACE('INTERNAL');
  APEX_UTIL.CREATE_USER(
    p_user_name => 'ADMIN',
    p_first_name => 'Admin',
    p_last_name => 'User',
    p_description => 'Administrator',
    p_email_address => 'admin@example.com',
    p_web_password => 'Welkom123',
    p_developer_privs => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N'
  );
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ APEX admin user created');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('⚠️  Admin user may already exist or error: ' || SQLERRM);
END;
/
EXIT;
EOF

echo "👤 Creating and enabling REST access for APEX_DEMO schema..."
sqlplus -s / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = XEPDB1;

BEGIN
  EXECUTE IMMEDIATE 'CREATE USER APEX_DEMO IDENTIFIED BY Welkom123';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -01920 THEN NULL;
    ELSE RAISE;
    END IF;
END;
/
GRANT CONNECT, RESOURCE TO APEX_DEMO;
ALTER USER APEX_DEMO QUOTA UNLIMITED ON USERS;

BEGIN
  ORDS_ADMIN.ENABLE_SCHEMA(
    p_enabled => TRUE,
    p_schema  => 'APEX_DEMO',
    p_url_mapping_type => 'BASE_PATH',
    p_url_mapping_pattern => 'apex_demo',
    p_auto_rest_auth => TRUE
  );
  COMMIT;
END;
/
EOF

echo "🧩 Creating default APEX workspace..."
sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = XEPDB1;
SET SERVEROUTPUT ON

DECLARE
  l_workspace_id NUMBER;
BEGIN
  APEX_UTIL.SET_WORKSPACE('INTERNAL');

  APEX_UTIL.CREATE_WORKSPACE(
    p_workspace => 'DEMO_WORKSPACE',
    p_primary_schema => 'APEX_DEMO'
  );

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('✅ Workspace DEMO_WORKSPACE created');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -20987 THEN
      DBMS_OUTPUT.PUT_LINE('⚠️  Workspace already exists');
    ELSE
      DBMS_OUTPUT.PUT_LINE('⚠️  Error creating workspace: ' || SQLERRM);
    END IF;
END;
/
EXIT;
EOF

sqlplus -s / as sysdba <<EOF
BEGIN
  FOR r IN (
    SELECT username FROM dba_users WHERE username IN ('APEX_PUBLIC_USER', 'APEX_REST_PUBLIC_USER', 'APEX_LISTENER')
  ) LOOP
    EXECUTE IMMEDIATE 'ALTER USER ' || r.username || ' IDENTIFIED BY Welkom123';
  END LOOP;
END;
/
EOF

echo "🔓 Unlocking APEX users in PDB..."
sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = XEPDB1;

BEGIN
  FOR r IN (SELECT username FROM dba_users WHERE username IN ('APEX_PUBLIC_USER', 'APEX_REST_PUBLIC_USER', 'APEX_LISTENER')) LOOP
    EXECUTE IMMEDIATE 'ALTER USER ' || r.username || ' ACCOUNT UNLOCK';
    DBMS_OUTPUT.PUT_LINE('Unlocked: ' || r.username);
  END LOOP;
END;
/
EXIT;
EOF

echo "✅ All done! APEX and ORDS are ready."
echo "🌐 Access APEX: http://localhost:8181/ords/"
echo "💻 Access SQL Developer Web: http://localhost:8181/ords/sql-developer"