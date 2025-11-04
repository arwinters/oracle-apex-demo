#!/bin/bash
set -e

if [ ! -f /etc/ords/config/.ords_registered ]; then
  echo '🔗 Registering ORDS with APEX...'
  /opt/oracle/scripts/setup/register_ords.sh
  touch /etc/ords/config/.ords_registered
  echo '✅ ORDS successfully registered.'
else
  echo 'ℹ️  ORDS already registered, skipping setup.'
fi

echo '🚀 Starting ORDS server...'
exec /opt/oracle/ords/bin/ords --config /etc/ords/config serve
