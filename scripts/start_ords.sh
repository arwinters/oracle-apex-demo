#!/bin/bash
set -e

# Setup logging
LOG_DIR="/opt/oracle/logs"
LOG_FILE="${LOG_DIR}/start-ords.log"
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

if [ ! -f /etc/ords/config/.ords_registered ]; then
  log '🔗 Registering ORDS with APEX...'
  /opt/oracle/scripts/setup/register_ords.sh
  touch /etc/ords/config/.ords_registered
  log '✅ ORDS successfully registered.'
else
  log 'ℹ️  ORDS already registered, skipping setup.'
fi

# Enable REST access for demo schema (must run AFTER ORDS registration)
# Create marker file to signal DB container to enable REST
if [ ! -f /etc/ords/config/.rest_enabled ]; then
  log '🔐 Signaling DB container to enable REST access...'
  touch /opt/oracle/logs/ords_registered_trigger

  # Wait for REST enablement to complete (max 30 seconds)
  for i in {1..30}; do
    if [ -f /opt/oracle/logs/rest_enabled_complete ]; then
      log '✅ REST access enabled successfully.'
      touch /etc/ords/config/.rest_enabled
      break
    fi
    sleep 1
  done

  if [ ! -f /opt/oracle/logs/rest_enabled_complete ]; then
    log '⚠️  Warning: REST enablement timeout, but continuing...'
  fi
fi

log '🚀 Starting ORDS server...'
exec /opt/oracle/ords/bin/ords --config /etc/ords/config serve
