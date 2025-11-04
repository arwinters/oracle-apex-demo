#!/bin/bash
set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/opt/oracle/config"
source "$CONFIG_DIR/config.env"

echo "🔍 Checking APEX installation files..."
if [ ! -f "/opt/oracle/apex/apexins.sql" ]; then
  echo "⚠️  APEX files not found in image - downloading from source..."
  echo "📦 Downloading Oracle APEX ${APEX_VERSION}..."
  cd /opt/oracle

  # Extract filename from URL
  APEX_ZIP=$(basename "$APEX_DOWNLOAD_URL")

  curl -s -o "$APEX_ZIP" "$APEX_DOWNLOAD_URL"
  unzip -q "$APEX_ZIP" && rm "$APEX_ZIP"

  # Move content up one level if nested directory exists
  if [ -d "/opt/oracle/apex/apex" ]; then
    echo "📂 Moving APEX files up one level..."
    mv /opt/oracle/apex/apex/* /opt/oracle/apex/
    rmdir /opt/oracle/apex/apex
  fi

  echo "✅ APEX ${APEX_VERSION} downloaded and extracted."
else
  echo "✅ APEX ${APEX_VERSION} files found in image (no download needed)."
fi

echo "⏳ Waiting for Oracle Database to be ready..."
sleep 10

# Convert version to schema check (e.g., 24.2.10 -> APEX_240210)
APEX_VERSION_CHECK="APEX_$(echo $APEX_VERSION | sed 's/\.//g')"

echo "🧠 Checking if APEX is already installed..."
if sqlplus -s / as sysdba <<EOF | grep -q "$APEX_VERSION_CHECK"
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT username FROM dba_users WHERE username LIKE 'APEX_%';
EXIT;
EOF
then
  echo "⚠️  APEX ${APEX_VERSION} already installed, skipping reinstallation."
else
  echo "🚀 Starting APEX installation..."
  cd /opt/oracle/apex
  sqlplus / as sysdba <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = XEPDB1;
@apexins.sql SYSAUX SYSAUX TEMP /i/
EXIT;
EOF
  echo "✅ APEX ${APEX_VERSION} installation complete."
fi

echo "🔐 Creating APEX admin user..."
sqlplus / as sysdba <<EOF
DEFINE APEX_ADMIN_USER='${APEX_ADMIN_USER}'
DEFINE APEX_ADMIN_EMAIL='${APEX_ADMIN_EMAIL}'
DEFINE APEX_ADMIN_PASSWORD='${APEX_ADMIN_PASSWORD}'
@${SCRIPT_DIR}/sql/01_create_admin_user.sql
EXIT;
EOF

echo "👤 Creating demo schema and enabling REST..."
sqlplus / as sysdba <<EOF
DEFINE DEMO_SCHEMA='${DEMO_SCHEMA}'
DEFINE ORACLE_PWD='${ORACLE_PWD}'
@${SCRIPT_DIR}/sql/02_create_demo_schema.sql
EXIT;
EOF

echo "🧩 Creating demo workspace..."
sqlplus / as sysdba <<EOF
DEFINE DEMO_WORKSPACE='${DEMO_WORKSPACE}'
DEFINE DEMO_SCHEMA='${DEMO_SCHEMA}'
@${SCRIPT_DIR}/sql/03_create_demo_workspace.sql
EXIT;
EOF

echo "🔐 Setting passwords for APEX system users..."
sqlplus / as sysdba <<EOF
DEFINE ORACLE_PWD='${ORACLE_PWD}'
@${SCRIPT_DIR}/sql/04_set_passwords.sql
EXIT;
EOF

echo "🔓 Unlocking APEX system users..."
sqlplus / as sysdba <<EOF
@${SCRIPT_DIR}/sql/05_unlock_apex_users.sql
EXIT;
EOF

echo "✅ All done! APEX ${APEX_VERSION} and ORDS are ready."
echo "🌐 Access APEX: http://localhost:8181/ords/"
echo "💻 Access SQL Developer Web: http://localhost:8181/ords/sql-developer"