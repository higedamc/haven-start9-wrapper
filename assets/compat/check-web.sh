#!/bin/bash

# ==============================================================================
# Haven Health Check Script
# ==============================================================================

# Check if Haven HTTP server is responding
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3355/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo '{"status":"success","message":"Haven is running and accessible"}'
    exit 0
else
    echo '{"status":"error","message":"Haven is not responding (HTTP '$HTTP_CODE')"}'
    exit 1
fi

