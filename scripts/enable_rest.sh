#!/bin/bash
set -e

# Load configuration
CONFIG_DIR="/opt/oracle/config"
source "$CONFIG_DIR/config.env"

# Setup logging
LOG_DIR="/opt/oracle/logs"
LOG_FILE="${LOG_DIR}/enable-rest.log"
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

log "🔐 Enabling REST access for demo schema..."
log "Executing 06_enable_rest_schema.sql..."

# Execute the REST enablement SQL
sqlplus / as sysdba <<EOF 2>&1 | tee -a "$LOG_FILE"
DEFINE DEMO_SCHEMA='${DEMO_SCHEMA}'
@/opt/oracle/scripts/setup/sql/06_enable_rest_schema.sql
EXIT;
EOF

if [ $? -eq 0 ]; then
  log "✅ REST access successfully enabled for schema: ${DEMO_SCHEMA}"
else
  log "⚠️  Failed to enable REST access"
  exit 1
fi
