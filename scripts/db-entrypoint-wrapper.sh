#!/bin/bash
set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/opt/oracle/config"
source "$CONFIG_DIR/config.env"

# Setup logging
LOG_DIR="/opt/oracle/logs"
LOG_FILE="${LOG_DIR}/db-entrypoint.log"
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

log "🚀 Starting Oracle Database with automatic APEX ${APEX_VERSION} installation..."

# Start Oracle database in background
/opt/oracle/runOracle.sh &
DB_PID=$!

# Wait for database to be ready
log "⏳ Waiting for database to be ready..."
while ! echo "SELECT 1 FROM DUAL;" | sqlplus -s / as sysdba 2>/dev/null | grep -q "1"; do
  sleep 5
  log "  ... still waiting for database"
done

log "✅ Database is ready!"

# Convert version to schema check (e.g., 24.2.10 -> APEX_240210)
APEX_VERSION_CHECK="APEX_$(echo $APEX_VERSION | sed 's/\.//g')"

# Check if APEX is installed, install if not
log "🔍 Checking if APEX ${APEX_VERSION} is installed..."
APEX_COUNT=$(sqlplus -s / as sysdba <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT COUNT(*) FROM dba_users WHERE username = '${APEX_VERSION_CHECK}';
EXIT;
EOF
)

if [ "$APEX_COUNT" -eq "1" ]; then
  log "✅ APEX ${APEX_VERSION} already installed"
  touch /tmp/apex_ready
else
  log "📦 Installing APEX ${APEX_VERSION}..."
  /opt/oracle/scripts/setup/install_apex.sh
  log "✅ APEX ${APEX_VERSION} installation complete!"
  touch /tmp/apex_ready
fi

# Start background watcher for REST enablement trigger
(
  while true; do
    if [ -f /opt/oracle/logs/ords_registered_trigger ] && [ ! -f /opt/oracle/logs/rest_enabled_complete ]; then
      log "🔐 ORDS registration detected, enabling REST access..."
      /opt/oracle/scripts/setup/enable_rest.sh
      touch /opt/oracle/logs/rest_enabled_complete
      break
    fi
    sleep 2
  done
) &

# Keep the database running
log "✅ Database ready with APEX ${APEX_VERSION}"
wait $DB_PID
