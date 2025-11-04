#!/bin/bash
set -e

echo "🚀 Starting Oracle Database with automatic APEX installation..."

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

# Check if APEX is installed, install if not
echo "🔍 Checking if APEX 24.2 is installed..."
APEX_COUNT=$(sqlplus -s / as sysdba <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT COUNT(*) FROM dba_users WHERE username = 'APEX_240200';
EXIT;
EOF
)

if [ "$APEX_COUNT" -eq "1" ]; then
  echo "✅ APEX 24.2 already installed"
else
  echo "📦 Installing APEX 24.2..."
  /opt/oracle/scripts/setup/install_apex.sh
  echo "✅ APEX 24.2 installation complete!"
fi

# Keep the database running
echo "✅ Database ready with APEX 24.2"
wait $DB_PID
