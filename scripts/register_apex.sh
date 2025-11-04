#!/bin/bash
set -e

echo "🔗 Registering ORDS with APEX inside XEPDB1..."

sqlplus -s / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = XEPDB1;

BEGIN
  ORDS.ENABLE_SCHEMA(
    p_enabled => TRUE,
    p_schema  => 'APEX_PUBLIC_USER',
    p_url_mapping_type => 'BASE_PATH',
    p_url_mapping_pattern => 'apex',
    p_auto_rest_auth => FALSE);
  COMMIT;
END;
/
EOF

echo "🚀 Running ORDS configuration..."

java -jar /opt/oracle/ords/ords.war install simple \
  --config /etc/ords/config \
  --db-hostname oracle-db \
  --db-port 1521 \
  --db-servicename XEPDB1 \
  --admin-user SYS \
  --password Welkom123 \
  --feature-rest-enabled true \
  --proxy-user \
  --log-folder /tmp/ords_logs \
  --silent

echo "✅ ORDS successfully registered with APEX."