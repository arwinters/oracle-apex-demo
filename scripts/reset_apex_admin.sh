#!/bin/bash
set -e

echo "🔐 Resetting APEX admin password..."

sqlplus / as sysdba <<EOF
ALTER SESSION SET CONTAINER = XEPDB1;

BEGIN
  APEX_UTIL.SET_WORKSPACE('INTERNAL');

  -- Reset admin password
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
END;
/

EXIT;
EOF

echo "✅ APEX admin password reset to: Welkom123"
