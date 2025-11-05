#!/bin/bash
set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/opt/oracle/config"
source "$CONFIG_DIR/config.env"

# Setup logging
LOG_DIR="/opt/oracle/logs"
LOG_FILE="${LOG_DIR}/install-apex.log"
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

log "🔍 Checking APEX installation files..."
if [ ! -f "/opt/oracle/apex/apexins.sql" ]; then
  log "⚠️  APEX files not found in image - downloading from source..."
  log "📦 Downloading Oracle APEX ${APEX_VERSION}..."
  cd /opt/oracle

  # Extract filename from URL
  APEX_ZIP=$(basename "$APEX_DOWNLOAD_URL")

  curl -s -o "$APEX_ZIP" "$APEX_DOWNLOAD_URL"
  unzip -q "$APEX_ZIP" && rm "$APEX_ZIP"

  # Move content up one level if nested directory exists
  if [ -d "/opt/oracle/apex/apex" ]; then
    log "📂 Moving APEX files up one level..."
    mv /opt/oracle/apex/apex/* /opt/oracle/apex/
    rmdir /opt/oracle/apex/apex
  fi

  log "✅ APEX ${APEX_VERSION} downloaded and extracted."
else
  log "✅ APEX ${APEX_VERSION} files found in image (no download needed)."
fi

log "⏳ Waiting for Oracle Database to be ready..."
sleep 10

# Convert version to schema check (e.g., 24.2.10 -> APEX_240210)
APEX_VERSION_CHECK="APEX_$(echo $APEX_VERSION | sed 's/\.//g')"

log "🧠 Checking if APEX is already installed..."
if sqlplus -s / as sysdba <<EOF | grep -q "$APEX_VERSION_CHECK"
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT username FROM dba_users WHERE username LIKE 'APEX_%';
EXIT;
EOF
then
  log "⚠️  APEX ${APEX_VERSION} already installed, skipping reinstallation."
else
  log "🚀 Starting APEX installation..."
  cd /opt/oracle/apex
  log "Executing apexins.sql..."
  sqlplus / as sysdba <<EOF 2>&1 | tee -a "$LOG_FILE"
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = XEPDB1;
@apexins.sql SYSAUX SYSAUX TEMP /i/
EXIT;
EOF
  log "✅ APEX ${APEX_VERSION} installation complete."
fi

log "🔐 Creating APEX admin user..."
log "Executing 01_create_admin_user.sql..."
sqlplus / as sysdba <<EOF 2>&1 | tee -a "$LOG_FILE"
DEFINE APEX_ADMIN_USER='${APEX_ADMIN_USER}'
DEFINE APEX_ADMIN_EMAIL='${APEX_ADMIN_EMAIL}'
DEFINE APEX_ADMIN_PASSWORD='${APEX_ADMIN_PASSWORD}'
@${SCRIPT_DIR}/sql/01_create_admin_user.sql
EXIT;
EOF

log "👤 Creating demo schema and enabling REST..."
log "Executing 02_create_demo_schema.sql..."
sqlplus / as sysdba <<EOF 2>&1 | tee -a "$LOG_FILE"
DEFINE DEMO_SCHEMA='${DEMO_SCHEMA}'
DEFINE ORACLE_PWD='${ORACLE_PWD}'
@${SCRIPT_DIR}/sql/02_create_demo_schema.sql
EXIT;
EOF

log "🧩 Creating demo workspace..."
log "Executing 03_create_demo_workspace.sql..."
sqlplus / as sysdba <<EOF 2>&1 | tee -a "$LOG_FILE"
DEFINE DEMO_WORKSPACE='${DEMO_WORKSPACE}'
DEFINE DEMO_SCHEMA='${DEMO_SCHEMA}'
@${SCRIPT_DIR}/sql/03_create_demo_workspace.sql
EXIT;
EOF

log "🔐 Setting passwords for APEX system users..."
log "Executing 04_set_passwords.sql..."
sqlplus / as sysdba <<EOF 2>&1 | tee -a "$LOG_FILE"
DEFINE ORACLE_PWD='${ORACLE_PWD}'
@${SCRIPT_DIR}/sql/04_set_passwords.sql
EXIT;
EOF

log "🔓 Unlocking APEX system users..."
log "Executing 05_unlock_apex_users.sql..."
sqlplus / as sysdba <<EOF 2>&1 | tee -a "$LOG_FILE"
@${SCRIPT_DIR}/sql/05_unlock_apex_users.sql
EXIT;
EOF

log "✅ All done! APEX ${APEX_VERSION} and ORDS are ready."
log "🌐 Access APEX: http://localhost:8181/ords/"
log "💻 Access SQL Developer Web: http://localhost:8181/ords/sql-developer"