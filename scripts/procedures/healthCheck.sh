#!/bin/bash

# ==============================================================================
# Haven Health Check Script
# ==============================================================================

set -e

# Check if Haven HTTP server is responding
if curl -sf http://localhost:3355 > /dev/null 2>&1; then
    echo '{"status":"success","message":"Haven is running and accessible"}'
    exit 0
else
    echo '{"status":"error","message":"Haven is not responding"}'
    exit 1
fi

