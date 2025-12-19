#!/bin/bash

################################################################################
# Report Generation Script
# Generates comprehensive system reports
################################################################################

set -euo pipefail

DATA_DIR="${DATA_DIR:-/app/data}"
REPORTS_DIR="${REPORTS_DIR:-/app/reports}"
HOURS="${1:-24}"

echo "Generating report for last $HOURS hours..."

# Run Python data processor
python3 /app/scripts/data_processor.py report --hours "$HOURS"

echo "Report generated successfully!"
echo "View at: $REPORTS_DIR/latest_report.html"
