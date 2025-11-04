#!/bin/bash
set -e

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/opt/oracle/config"
source "$CONFIG_DIR/config.env"

echo "🚀 Starting Oracle Database with automatic APEX ${APEX_VERSION} installation..."

# Start Oracle database in background
/opt/oracle/runOracle.sh &
DB_PID=$!

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
while ! echo "SELECT 1 FROM DUAL;" | sqlplus -s / as sysdba 2>/dev/null | grep -q "1"; do
  sleep 5
  echo "  ... still waiting for database"
done

echo "✅ Database is ready!"

# Convert version to schema check (e.g., 24.2.10 -> APEX_240210)
APEX_VERSION_CHECK="APEX_$(echo $APEX_VERSION | sed 's/\.//g')"

# Check if APEX is installed, install if not
echo "🔍 Checking if APEX ${APEX_VERSION} is installed..."
APEX_COUNT=$(sqlplus -s / as sysdba <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT COUNT(*) FROM dba_users WHERE username = '${APEX_VERSION_CHECK}';
EXIT;
EOF
)

if [ "$APEX_COUNT" -eq "1" ]; then
  echo "✅ APEX ${APEX_VERSION} already installed"
else
  echo "📦 Installing APEX ${APEX_VERSION}..."
  /opt/oracle/scripts/setup/install_apex.sh
  echo "✅ APEX ${APEX_VERSION} installation complete!"
fi

# Keep the database running
echo "✅ Database ready with APEX ${APEX_VERSION}"
wait $DB_PID
