#!/bin/bash

################################################################################
# Dashboard GUI Launcher
# Starts the web-based monitoring dashboard
################################################################################

set -euo pipefail

PORT="${WEB_PORT:-3000}"

echo "Starting monitoring dashboard on port $PORT..."
echo "Access dashboard at: http://localhost:$PORT"

cd /app/web
exec npm start
