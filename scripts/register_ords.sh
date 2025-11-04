#!/bin/bash
set -e

echo "🚀 Registering ORDS with APEX database..."

# Short wait to ensure DB is fully ready
sleep 10

/opt/oracle/ords/bin/ords install --admin-user SYS --db-hostname oracle-db --db-port 1521 --db-servicename XEPDB1 --feature-rest-enabled-sql true --feature-sdw true --password-stdin <<EOF
$ORACLE_PWD
EOF

echo "📁 Configuring APEX static files..."
/opt/oracle/ords/bin/ords config set standalone.static.path /opt/oracle/apex/images

echo "✅ ORDS registration complete!"
echo "🌐 APEX Admin available at: http://localhost:8181/ords/apex_admin"