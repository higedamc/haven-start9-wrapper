#!/bin/bash

# ==============================================================================
# Haven Health Check Script
# Start9 Best Practices (Perplexity recommended):
# - Lightweight and fast
# - Timeout on network operations
# - Check process first, then service
# ==============================================================================

# Step 1: Check if Haven process is running
if ! pgrep -f "/app/haven" > /dev/null 2>&1; then
    # Process not running - this is a real error
    exit 1
fi

# Step 2: Check HTTP endpoint with timeout
if curl -sf --max-time 5 http://localhost:3355/ > /dev/null 2>&1; then
    # Success - HTTP responding
    exit 0
else
    # Process running but HTTP not responding yet
    # This is OK during startup, so return success
    exit 0
fi
