#!/bin/bash

# ==============================================================================
# Haven Import Notes Action
# Executes Haven with --import flag to import historical notes
# ==============================================================================

# IMMEDIATE DEBUG OUTPUT
echo "===========================================" >&2
echo "DEBUG: importNotes.sh started" >&2
echo "DEBUG: PWD=$(pwd)" >&2
echo "DEBUG: USER=$(whoami)" >&2
echo "DEBUG: Args: $@" >&2
echo "DEBUG: ENV vars check:" >&2
echo "  IMPORT_START_DATE=${IMPORT_START_DATE:-NOT_SET}" >&2
echo "  IMPORT_SEED_RELAYS=${IMPORT_SEED_RELAYS:-NOT_SET}" >&2
echo "  OWNER_NPUB=${OWNER_NPUB:-NOT_SET}" >&2
echo "  CONFIG_FILE=${CONFIG_FILE:-NOT_SET}" >&2
echo "===========================================" >&2

# Error handler
error_exit() {
    echo "DEBUG: error_exit called with: $1" >&2
    cat <<EOF
{
  "version": "0",
  "message": "Script error: $1",
  "value": null,
  "qr": false,
  "copyable": false
}
EOF
    exit 1
}

# Set error handling
set -e
trap 'error_exit "Script failed at line $LINENO"' ERR

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

IMPORT_LOG="/app/logs/import-$(date +%Y%m%d-%H%M%S).log"
mkdir -p /app/logs 2>/dev/null || true

# Logging functions - output to stderr for debugging, and optionally to log file
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$IMPORT_LOG" >&2 || echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$IMPORT_LOG" >&2 || echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$IMPORT_LOG" >&2 || echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1" | tee -a "$IMPORT_LOG" >&2 || echo -e "${CYAN}[DEBUG]${NC} $1" >&2
}

log_progress() {
    echo -e "${BLUE}[PROGRESS]${NC} $1" | tee -a "$IMPORT_LOG" >&2 || echo -e "${BLUE}[PROGRESS]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$IMPORT_LOG" >&2 || echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

# Print banner to stderr
{
    echo ""
    echo "============================================="
    echo "   Haven Import Notes - Detailed Log"
    echo "============================================="
    echo ""
} >&2
log_info "Import started at: $(date '+%Y-%m-%d %H:%M:%S')"
log_info "Log file: $IMPORT_LOG"
echo "" >&2

# Load configuration from environment variables (already set by docker_entrypoint.sh)
log_info "Loading configuration from environment..."
echo "DEBUG: Before config check - CONFIG_FILE=${CONFIG_FILE}" >&2
echo "DEBUG: Before config check - IMPORT_START_DATE=${IMPORT_START_DATE}" >&2

# Use environment variables that were already loaded by docker_entrypoint.sh
# If not set, try to read from config file as fallback
if [ -z "$IMPORT_START_DATE" ] && [ -f "$CONFIG_FILE" ]; then
    echo "DEBUG: Reading from config file: $CONFIG_FILE" >&2
    log_debug "Environment variable not set, reading from config file..."
    IMPORT_START_DATE=$(yq e '.import-start-date // ""' "$CONFIG_FILE")
    IMPORT_SEED_RELAYS=$(yq e '.import-seed-relays // ""' "$CONFIG_FILE")
    IMPORT_OWNER_NOTES_TIMEOUT=$(yq e '.import-owner-notes-timeout // "30"' "$CONFIG_FILE")
    IMPORT_TAGGED_NOTES_TIMEOUT=$(yq e '.import-tagged-notes-timeout // "120"' "$CONFIG_FILE")
    OWNER_NPUB=$(yq e '.owner-npub // ""' "$CONFIG_FILE")
    echo "DEBUG: After reading config - OWNER_NPUB=${OWNER_NPUB}" >&2
elif [ -z "$IMPORT_START_DATE" ]; then
    echo "DEBUG: Config file not found or not readable: $CONFIG_FILE" >&2
    log_error "Config file not accessible!"
fi

echo "DEBUG: Final values:" >&2
echo "  OWNER_NPUB=${OWNER_NPUB:-NOT_SET}" >&2
echo "  IMPORT_START_DATE=${IMPORT_START_DATE:-NOT_SET}" >&2
echo "  IMPORT_SEED_RELAYS=${IMPORT_SEED_RELAYS:-NOT_SET}" >&2

# Validate configuration
if [ -z "$OWNER_NPUB" ]; then
    log_error "Owner NPub not configured!"
    cat <<EOF
{
  "version": "0",
  "message": "Owner NPub is not configured. Please set 'Owner Nostr Public Key' in the config first.",
  "value": null,
  "qr": false,
  "copyable": false
}
EOF
    exit 1
fi

log_info "Configuration validated successfully!" >&2

echo "" >&2
log_info "========================================="
log_info "Import Configuration"
log_info "========================================="
log_info "Owner NPub: ${OWNER_NPUB:0:20}...${OWNER_NPUB: -10}"
log_info "Start Date: ${IMPORT_START_DATE:-not set}"
log_info "Owner Notes Timeout: ${IMPORT_OWNER_NOTES_TIMEOUT}s"
log_info "Tagged Notes Timeout: ${IMPORT_TAGGED_NOTES_TIMEOUT}s"

# Validate configuration
if [ -z "$IMPORT_START_DATE" ]; then
    log_error "Import start date is not configured!"
    log_error "Please configure 'Import Start Date' in the config before running import."
    cat <<EOF
{
  "version": "0",
  "message": "Import start date not configured. Please set 'Import Start Date' in the config.",
  "value": null,
  "qr": false,
  "copyable": false
}
EOF
    exit 1
fi

# Count relays and show detailed relay list
RELAY_COUNT=0
if [ -n "$IMPORT_SEED_RELAYS" ]; then
    RELAY_COUNT=$(echo "$IMPORT_SEED_RELAYS" | tr ',' '\n' | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
fi

log_info "Seed Relays: ${RELAY_COUNT} configured"

if [ "$RELAY_COUNT" -eq 0 ]; then
    log_error "No import seed relays configured!"
    log_error "Please configure 'Import Seed Relays' in the config before running import."
    cat <<EOF
{
  "version": "0",
  "message": "No import seed relays configured. Please set 'Import Seed Relays' in the config.",
  "value": null,
  "qr": false,
  "copyable": false
}
EOF
    exit 1
fi

# Show relay list
log_debug "Relay list:"
echo "$IMPORT_SEED_RELAYS" | tr ',' '\n' | grep -v '^[[:space:]]*$' | while read -r relay; do
    log_debug "  - $relay"
done

# Calculate estimated time range
START_EPOCH=$(date -d "$IMPORT_START_DATE" "+%s" 2>/dev/null || echo "0")
NOW_EPOCH=$(date "+%s")
if [ "$START_EPOCH" = "0" ]; then
    DAYS_DIFF=365
    ESTIMATED_BATCHES=37
else
    DAYS_DIFF=$(( (NOW_EPOCH - START_EPOCH) / 86400 ))
    ESTIMATED_BATCHES=$(( DAYS_DIFF / 10 + 1 ))
fi

log_info "========================================="
log_info "Time Range Analysis"
log_info "========================================="
log_info "Days to import: ~${DAYS_DIFF} days"
log_info "Estimated batches: ~${ESTIMATED_BATCHES} (10 days each)"
log_info "Estimated time: $(( ESTIMATED_BATCHES * IMPORT_OWNER_NOTES_TIMEOUT / 60 ))-$(( ESTIMATED_BATCHES * IMPORT_OWNER_NOTES_TIMEOUT / 30 )) minutes"

echo "" >&2
log_info "========================================="
log_info "Creating Import Request"
log_info "========================================="

# Create flag file to signal docker_entrypoint.sh to run import
FLAG_FILE="/data/import-requested"
log_info "Creating import request flag: $FLAG_FILE" >&2

if touch "$FLAG_FILE" 2>&1; then
    log_success "Import request flag created successfully" >&2
else
    log_error "Failed to create import request flag" >&2
    cat <<EOF
{
  "version": "0",
  "message": "Failed to create import request flag at $FLAG_FILE. Check permissions.",
  "value": null,
  "qr": false,
  "copyable": false
}
EOF
    exit 1
fi

# Calculate estimated time
ESTIMATED_MINUTES=$(( ESTIMATED_BATCHES * IMPORT_OWNER_NOTES_TIMEOUT / 60 ))
if [ "$ESTIMATED_MINUTES" -lt 10 ]; then
    TIME_DISPLAY="10-30 minutes"
elif [ "$ESTIMATED_MINUTES" -lt 60 ]; then
    TIME_DISPLAY="${ESTIMATED_MINUTES}-$(( ESTIMATED_MINUTES * 2 )) minutes"
else
    ESTIMATED_HOURS=$(( ESTIMATED_MINUTES / 60 ))
    TIME_DISPLAY="${ESTIMATED_HOURS}-$(( ESTIMATED_HOURS * 2 )) hours"
fi

# Return success message with restart instructions
log_success "Import configured successfully!" >&2
cat <<EOF
{
  "version": "0",
  "message": "✅ Import Configured Successfully!\n\n📋 Configuration:\n  • Owner: ${OWNER_NPUB:0:20}...${OWNER_NPUB: -10}\n  • Start Date: ${IMPORT_START_DATE}\n  • Relays: ${RELAY_COUNT}\n  • Days to import: ~${DAYS_DIFF}\n\n⏱️  Estimated Time: ${TIME_DISPLAY}\n\n🔄 Next Steps:\n1. **RESTART Haven service** to begin import\n2. Monitor logs for progress\n3. Haven will automatically restart in normal mode after import completes\n\n⚠️  Do not stop Haven during the import process!",
  "value": null,
  "qr": false,
  "copyable": true
}
EOF
exit 0

# The rest of the code below is not executed in this action
# It will be executed by docker_entrypoint.sh when the flag file is detected

# Export environment variables for Haven
export IMPORT_START_DATE
export IMPORT_OWNER_NOTES_FETCH_TIMEOUT_SECONDS=$IMPORT_OWNER_NOTES_TIMEOUT
export IMPORT_TAGGED_NOTES_FETCH_TIMEOUT_SECONDS=$IMPORT_TAGGED_NOTES_TIMEOUT
export RUN_IMPORT=true

# Load other necessary environment variables from config
export OWNER_NPUB=$(yq e '.owner-npub' /data/start9/config.yaml)
export DB_ENGINE=$(yq e '.db-engine // "badger"' /data/start9/config.yaml)
export RELAY_VERSION="1.2.3"
export LOG_LEVEL=$(yq e '.log-level // "INFO"' /data/start9/config.yaml)

# Read Tor address
if [ -f /data/tor_address.txt ]; then
    export TOR_ADDRESS=$(cat /data/tor_address.txt)
else
    export TOR_ADDRESS="unknown.onion"
fi

# Generate Haven config
log_info "Generating Haven configuration..."
cat > /app/.env <<EOF
OWNER_NPUB=${OWNER_NPUB}
DB_ENGINE=${DB_ENGINE:-badger}
BLOSSOM_PATH=/data/blossom/
RELAY_URL=${TOR_ADDRESS}
RELAY_PORT=3355
RELAY_BIND_ADDRESS=0.0.0.0
RELAY_VERSION=${RELAY_VERSION:-1.2.0}
IMPORT_START_DATE=${IMPORT_START_DATE}
IMPORT_OWNER_NOTES_FETCH_TIMEOUT_SECONDS=${IMPORT_OWNER_NOTES_TIMEOUT}
IMPORT_TAGGED_NOTES_FETCH_TIMEOUT_SECONDS=${IMPORT_TAGGED_NOTES_TIMEOUT}
IMPORT_QUERY_INTERVAL_SECONDS=360000
IMPORT_SEED_RELAYS_FILE=/app/relays_import.json
BLASTR_RELAYS_FILE=/app/relays_blastr.json
HAVEN_LOG_LEVEL=${LOG_LEVEL:-INFO}
EOF

echo "" >&2
log_info "========================================="
log_info "Starting Haven Import Process"
log_info "========================================="
echo "" >&2

# Variables for progress tracking
TOTAL_OWNER_NOTES=0
TOTAL_TAGGED_NOTES=0
CURRENT_BATCH=0
FAILED_NOTES=0
START_TIME=$(date +%s)

# Run Haven with --import flag and parse output for progress
cd /app
su-exec haven /app/haven --import 2>&1 | while IFS= read -r line; do
    # Log everything to file
    echo "$line" >> "$IMPORT_LOG"
    
    # Parse and highlight important events
    if echo "$line" | grep -q "Testing import relays"; then
        log_progress "Testing connection to seed relays..."
    elif echo "$line" | grep -q "Connected to relay"; then
        relay_url=$(echo "$line" | grep -o 'relay=[^ ]*' | cut -d= -f2)
        log_debug "✓ Connected: $relay_url"
    elif echo "$line" | grep -q "Error connecting to relay"; then
        relay_url=$(echo "$line" | grep -o 'relay=[^ ]*' | cut -d= -f2)
        log_warn "✗ Failed: $relay_url"
    elif echo "$line" | grep -q "All relays connected successfully"; then
        log_success "All seed relays connected successfully!"
    elif echo "$line" | grep -q "Imported .* notes from"; then
        # Extract batch info
        batch_notes=$(echo "$line" | grep -o 'Imported [0-9]*' | grep -o '[0-9]*')
        date_range=$(echo "$line" | grep -o 'from [0-9-]* to [0-9-]*')
        CURRENT_BATCH=$((CURRENT_BATCH + 1))
        TOTAL_OWNER_NOTES=$((TOTAL_OWNER_NOTES + batch_notes))
        
        # Calculate progress
        PROGRESS_PCT=$(( CURRENT_BATCH * 100 / ESTIMATED_BATCHES ))
        ELAPSED=$(($(date +%s) - START_TIME))
        if [ $CURRENT_BATCH -gt 0 ]; then
            AVG_TIME_PER_BATCH=$(( ELAPSED / CURRENT_BATCH ))
            REMAINING_BATCHES=$(( ESTIMATED_BATCHES - CURRENT_BATCH ))
            ETA_SECONDS=$(( AVG_TIME_PER_BATCH * REMAINING_BATCHES ))
            ETA_MINUTES=$(( ETA_SECONDS / 60 ))
            
            log_progress "Batch $CURRENT_BATCH/$ESTIMATED_BATCHES ($PROGRESS_PCT%) - $batch_notes notes $date_range"
            log_debug "Total so far: $TOTAL_OWNER_NOTES notes | ETA: ~${ETA_MINUTES}m"
        else
            log_progress "Batch $CURRENT_BATCH - $batch_notes notes $date_range"
        fi
    elif echo "$line" | grep -q "No notes found for"; then
        CURRENT_BATCH=$((CURRENT_BATCH + 1))
        date_range=$(echo "$line" | grep -o '[0-9-]* to [0-9-]*')
        log_debug "Batch $CURRENT_BATCH/$ESTIMATED_BATCHES - No notes for $date_range"
    elif echo "$line" | grep -q "owner note import complete"; then
        final_count=$(echo "$line" | grep -o 'Imported [0-9]*' | grep -o '[0-9]*')
        log_success "Owner notes import complete! Total: $final_count notes"
        TOTAL_OWNER_NOTES=$final_count
    elif echo "$line" | grep -q "importing inbox notes"; then
        echo "" >&2
        log_progress "Starting tagged notes import (mentions, replies, reactions, zaps)..."
    elif echo "$line" | grep -q "imported .* tagged notes"; then
        tagged_count=$(echo "$line" | grep -o 'imported [0-9]*' | grep -o '[0-9]*')
        TOTAL_TAGGED_NOTES=$tagged_count
        log_success "Tagged notes import complete! Total: $tagged_count notes"
    elif echo "$line" | grep -q "error importing"; then
        FAILED_NOTES=$((FAILED_NOTES + 1))
        log_warn "Note import error (total errors: $FAILED_NOTES)"
    elif echo "$line" | grep -q "Timeout.*while importing"; then
        log_warn "Timeout occurred - consider increasing timeout values"
    elif echo "$line" | grep -q "tagged import complete"; then
        log_success "Import process finished!"
    fi
done

EXIT_CODE=${PIPESTATUS[0]}

echo "" >&2
echo "" >&2

# Calculate final statistics
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))
TOTAL_MINUTES=$((TOTAL_TIME / 60))
TOTAL_SECONDS=$((TOTAL_TIME % 60))
TOTAL_NOTES=$((TOTAL_OWNER_NOTES + TOTAL_TAGGED_NOTES))

log_info "========================================="
log_info "Import Summary"
log_info "========================================="
log_info "Completion time: $(date '+%Y-%m-%d %H:%M:%S')"
log_info "Duration: ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s"
log_info ""
log_info "Results:"
log_info "  • Owner notes imported: $TOTAL_OWNER_NOTES"
log_info "  • Tagged notes imported: $TOTAL_TAGGED_NOTES"
log_info "  • Total notes imported: $TOTAL_NOTES"
if [ $FAILED_NOTES -gt 0 ]; then
    log_warn "  • Failed imports: $FAILED_NOTES"
fi
log_info ""
log_info "Storage locations:"
log_info "  • Owner notes → Outbox relay"
log_info "  • Tagged notes → Inbox relay"
log_info "  • Gift wraps → Chat relay"
log_info ""
log_info "Next steps:"
log_info "  1. Restart Haven in normal mode"
log_info "  2. Connect your Nostr client"
log_info "  3. Verify imported notes are visible"
log_info "========================================="
echo "" >&2

if [ $EXIT_CODE -eq 0 ]; then
    log_success "✅ Import completed successfully!"
    log_info "Full log saved to: $IMPORT_LOG"
    
    # Output JSON result for Start9
    cat <<EOF
{
  "version": "0",
  "message": "Import completed: $TOTAL_NOTES notes ($TOTAL_OWNER_NOTES owner + $TOTAL_TAGGED_NOTES tagged) in ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s",
  "value": null,
  "qr": false,
  "copyable": true
}
EOF
    exit 0
else
    log_error "🚫 Import failed with exit code $EXIT_CODE"
    log_info "Full log saved to: $IMPORT_LOG"
    
    # Output JSON error for Start9
    cat <<EOF
{
  "version": "0",
  "message": "Import failed with exit code $EXIT_CODE after ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s. Imported: $TOTAL_NOTES notes before failure. Check logs for details.",
  "value": null,
  "qr": false,
  "copyable": true
}
EOF
    exit $EXIT_CODE
fi

