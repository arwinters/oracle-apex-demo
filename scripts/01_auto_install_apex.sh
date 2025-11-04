#!/bin/bash
# This script runs on every database startup
# It checks if APEX is installed, and if not, runs the installation

echo "🔍 Checking if APEX needs to be installed..."

# Check if APEX 24.2 is already installed
APEX_INSTALLED=$(sqlplus -s / as sysdba <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT COUNT(*) FROM dba_users WHERE username = 'APEX_240200';
EXIT;
EOF
)

if [ "$APEX_INSTALLED" -eq "1" ]; then
  echo "✅ APEX 24.2 is already installed, skipping installation."
  exit 0
fi

echo "🚀 APEX 24.2 not found, starting installation..."
/opt/oracle/scripts/setup/install_apex.sh
