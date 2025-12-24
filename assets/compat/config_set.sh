#!/bin/bash

# ==============================================================================
# Haven Configuration Set Script
# Validates configuration from Start9 UI
# StartOS will automatically save the config to /root/start9/config.yaml
# ==============================================================================

set -e

# Read new config from stdin
CONFIG=$(cat)

# Validate required fields
OWNER_NPUB=$(echo "$CONFIG" | yq e '.owner-npub' -)

# Check if owner-npub is provided and not null
if [ -z "$OWNER_NPUB" ] || [ "$OWNER_NPUB" = "null" ] || [ "$OWNER_NPUB" = "~" ]; then
    echo "Error: owner-npub is required" >&2
    exit 1
fi

# Validate npub format
if [[ ! "$OWNER_NPUB" =~ ^npub1[a-z0-9]{58}$ ]]; then
    echo "Error: Invalid npub format. Must start with 'npub1' and be 63 characters long (e.g., npub1abc...xyz)" >&2
    exit 1
fi

# Return the validated config (StartOS will handle saving)
echo "$CONFIG"

exit 0
