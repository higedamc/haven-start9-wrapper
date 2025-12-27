#!/bin/bash

# ==============================================================================
# Haven Health Check Script
# ==============================================================================

set -e

# Check if Haven HTTP server is responding
# Try both the main page and dashboard endpoint
if curl -sf http://localhost:3355/ > /dev/null 2>&1; then
    # Also check if dashboard is accessible
    if curl -sf http://localhost:3355/dashboard > /dev/null 2>&1; then
        echo '{"status":"success","message":"Haven and Dashboard are accessible"}'
        exit 0
    else
        echo '{"status":"success","message":"Haven is accessible (Dashboard initializing)"}'
        exit 0
    fi
else
    echo '{"status":"error","message":"Haven is not responding"}'
    exit 1
fi

