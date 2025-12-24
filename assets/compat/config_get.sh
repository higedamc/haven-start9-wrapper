#!/bin/bash

# ==============================================================================
# Haven Configuration Get Script
# Returns default configuration values in YAML format for Start9 UI
# StartOS will merge these defaults with user-provided values automatically
# ==============================================================================

set -e

# Return default configuration values
# owner-npub is omitted because it's required (nullable: false) and has no default
cat <<EOF
db-engine: badger
lmdb-mapsize: 10240
relay-version: "1.0.6"
private-relay-name: "Haven Private"
private-relay-description: "My private relay"
chat-relay-name: "Haven Chat"
chat-relay-description: "My chat relay"
chat-wot-depth: 2
chat-wot-refresh-interval: 24
chat-minimum-followers: 10
outbox-relay-name: "Haven Outbox"
outbox-relay-description: "My outbox relay"
inbox-relay-name: "Haven Inbox"
inbox-relay-description: "My inbox relay"
inbox-pull-interval: 3600
import-enabled: false
backup-enabled: false
backup-provider: none
backup-interval: 24
log-level: INFO
EOF
