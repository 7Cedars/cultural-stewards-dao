#!/bin/bash

# Navigate to the Foundry project root (contracts directory)
# This allows the script to be run from anywhere and correctly use forge
cd "$(dirname "$0")/../.."

# Exit on error
set -e

# Load .env variables if .env file exists
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Arguments or environment variables
IDEAS_LAYERS="${1:-$IDEAS_LAYERS}"
NONCE="${2:-$NONCE}"
URI="${3:-$IDEAS_URI}"
PRIVATE_KEYS="${4:-$PRIVATE_KEYS}"
EXTRA_ARGS=("${@:5}") # Any additional arguments like --broadcast, --private-key, etc.

if [ -z "$IDEAS_LAYERS" ] || [ -z "$NONCE" ] || [ -z "$URI" ] || [ -z "$PRIVATE_KEYS" ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <IDEAS_LAYERS_ARRAY> <NONCE> <URI> <PRIVATE_KEYS_ARRAY> [EXTRA_ARGS...]"
    echo "Example: $0 \"[0x123..., 0x456...]\" 0 \"https://example.com/\" \"[1, 2]\" --broadcast"
    echo "Note: Arguments can also be provided via .env file variables (IDEAS_LAYERS, NONCE, URI, PRIVATE_KEYS)."
    exit 1
fi

# 6 minutes in seconds
INTERVAL=360

countdown() {
    local secs=$1
    while [ $secs -gt 0 ]; do
        printf "\rWaiting: %02d:%02d before next step..." $((secs/60)) $((secs%60))
        sleep 1
        secs=$((secs - 1))
    done
    printf "\rWaiting: 00:00 before next step...\n"
}

echo "=========================================================="
echo "Starting Ideas Layer Setup Process"
echo "Ideas Layers: $IDEAS_LAYERS"
echo "Nonce: $NONCE"
echo "URI: $URI"
echo "Interval: 6 minutes ($INTERVAL seconds) between steps"
echo "=========================================================="
echo ""

echo "[1/3] Executing runSetupMandate for each Ideas Layer..."
while IFS= read -r layer; do
    [ -z "$layer" ] && continue
    echo "  Running setup mandate for layer: $layer"
    forge script governance/actions/Initialise.s.sol:Initialise \
        --sig "runSetupMandate(address,uint256,uint256[])" \
        "$layer" "$NONCE" "$PRIVATE_KEYS" \
        "${EXTRA_ARGS[@]}"
done < <(echo "$IDEAS_LAYERS" | tr -d '[]' | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
echo "runSetupMandate completed for all layers."

echo ""
countdown $INTERVAL
echo ""

echo "[2/3] Executing updateUriIdeasLayer1 (propose and vote)..."
forge script governance/actions/Initialise.s.sol:Initialise \
    --sig "updateUriIdeasLayer1(address[],string,uint256,uint256[])" \
    "$IDEAS_LAYERS" "$URI" "$NONCE" "$PRIVATE_KEYS" \
    "${EXTRA_ARGS[@]}"
echo "updateUriIdeasLayer1 completed successfully."

echo ""
countdown $INTERVAL
echo ""

echo "[3/3] Executing updateUriIdeasLayer2 (execute)..."
forge script governance/actions/Initialise.s.sol:Initialise \
    --sig "updateUriIdeasLayer2(address[],string,uint256,uint256[])" \
    "$IDEAS_LAYERS" "$URI" "$NONCE" "$PRIVATE_KEYS" \
    "${EXTRA_ARGS[@]}"
echo "updateUriIdeasLayer2 completed successfully."

echo ""
echo "=========================================================="
echo "Ideas Layer Setup Complete!"
echo "=========================================================="
