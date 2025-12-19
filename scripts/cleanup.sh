#!/bin/bash

################################################################################
# Cleanup Script
# Removes old metrics and reports
################################################################################

set -euo pipefail

DAYS="${1:-7}"

echo "Cleaning up files older than $DAYS days..."

# Run Python cleanup
python3 /app/scripts/data_processor.py cleanup --days "$DAYS"

echo "Cleanup complete!"
