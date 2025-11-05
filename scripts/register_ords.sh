#!/bin/bash
set -e

# Setup logging
LOG_DIR="/opt/oracle/logs"
LOG_FILE="${LOG_DIR}/register-ords.log"
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

log "🚀 Registering ORDS with APEX database..."

# Short wait to ensure DB is fully ready
sleep 10

log "Executing ORDS install command..."
/opt/oracle/ords/bin/ords install --admin-user SYS --db-hostname oracle-db --db-port 1521 --db-servicename XEPDB1 --feature-rest-enabled-sql true --feature-sdw true --password-stdin <<EOF 2>&1 | tee -a "$LOG_FILE"
$ORACLE_PWD
EOF

log "📁 Configuring APEX static files..."
/opt/oracle/ords/bin/ords config set standalone.static.path /opt/oracle/apex/images 2>&1 | tee -a "$LOG_FILE"

log "✅ ORDS registration complete!"
log "🌐 APEX Admin available at: http://localhost:8181/ords/apex_admin"