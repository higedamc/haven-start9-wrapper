#!/bin/bash

# ==============================================================================
# Haven Properties Display Script
# Shows real-time service information in Start9 UI
# ==============================================================================

set -e

# Get Tor address
if [ -f /data/tor_address.txt ]; then
    TOR_ADDRESS=$(cat /data/tor_address.txt)
else
    TOR_ADDRESS="Generating..."
fi

# Get database stats
if [ -d /data/db ]; then
    DB_SIZE=$(du -sh /data/db 2>/dev/null | cut -f1 || echo "0B")
else
    DB_SIZE="0B"
fi

# Get Blossom storage stats
if [ -d /data/blossom ]; then
    BLOSSOM_SIZE=$(du -sh /data/blossom 2>/dev/null | cut -f1 || echo "0B")
    BLOSSOM_FILES=$(find /data/blossom -type f 2>/dev/null | wc -l || echo "0")
else
    BLOSSOM_SIZE="0B"
    BLOSSOM_FILES="0"
fi

# Get Haven version from config
if [ -f /data/start9/config.yaml ]; then
    VERSION=$(yq e '.["relay-version"] // "1.1.4"' /data/start9/config.yaml 2>/dev/null || echo "1.1.4")
else
    VERSION="1.1.4"
fi

# Get Blastr relay configuration
BLASTR_RELAYS=""
BLASTR_COUNT="0"
if [ -f /data/start9/config.yaml ]; then
    BLASTR_RELAYS=$(yq e '.["blastr-relays"] // ""' /data/start9/config.yaml 2>/dev/null || echo "")
    if [ -n "$BLASTR_RELAYS" ] && [ "$BLASTR_RELAYS" != "null" ]; then
        BLASTR_COUNT=$(echo "$BLASTR_RELAYS" | tr ',' '\n' | wc -l | tr -d ' ')
    fi
fi

# Output as YAML for Start9
cat <<EOF
version: 2
data:
  Haven Version:
    type: string
    value: "$VERSION"
    description: Current Haven version
  
  Service Status:
    type: string
    value: "Running"
    description: Haven service status
    qr: false
  
  Tor Hidden Service:
    type: string
    value: "$TOR_ADDRESS"
    description: Your .onion address (Hidden Service)
    copyable: true
    qr: true
    masked: false
  
  Outbox Relay:
    type: string
    value: "ws://$TOR_ADDRESS"
    description: Public relay URL (anyone can read, only you can write)
    copyable: true
    qr: true
    masked: false
  
  Private Relay:
    type: string
    value: "ws://$TOR_ADDRESS/private"
    description: Private relay URL (authentication required)
    copyable: true
    qr: true
    masked: false
  
  Chat Relay:
    type: string
    value: "ws://$TOR_ADDRESS/chat"
    description: Chat relay URL (Web of Trust protected)
    copyable: true
    qr: true
    masked: false
  
  Inbox Relay:
    type: string
    value: "ws://$TOR_ADDRESS/inbox"
    description: Inbox relay URL (Web of Trust protected)
    copyable: true
    qr: true
    masked: false
  
  Blossom Media Server:
    type: string
    value: "http://$TOR_ADDRESS"
    description: Blossom media server URL (NIP-96 & BUD-02 compliant)
    copyable: true
    qr: true
    masked: false
  
  Database Size:
    type: string
    value: "$DB_SIZE"
    description: Total database storage used
    qr: false
  
  Media Storage:
    type: string
    value: "$BLOSSOM_FILES files ($BLOSSOM_SIZE)"
    description: Number of media files and total size
    qr: false
  
  Total Storage:
    type: string
    value: "$(du -sh /data 2>/dev/null | cut -f1 || echo "0B")"
    description: Total Haven data storage
    qr: false
  
  Blastr Relays:
    type: string
    value: "$BLASTR_COUNT relay(s) configured"
    description: Number of Blastr relays for event broadcasting
    qr: false
EOF

