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
# IDEAS_LAYERS should be a space-separated list of Ideas Layer addresses in .env,
# e.g.: IDEAS_LAYERS="0xAbc... 0xDef... 0x123..."
# Falls back to the singular IDEAS_LAYER if IDEAS_LAYERS is not set.
IDEAS_LAYERS="${1:-${IDEAS_LAYERS:-$IDEAS_LAYER}}"
NONCE="${2:-$NONCE}"
PRIVATE_KEYS="${3:-$PRIVATE_KEYS}"
EXTRA_ARGS=("${@:4}") # Any additional arguments like --broadcast, --rpc-url, etc.

if [ -z "$IDEAS_LAYERS" ] || [ -z "$NONCE" ] || [ -z "$PRIVATE_KEYS" ]; then
    echo "Error: Missing required arguments."
    echo "Usage: $0 <IDEAS_LAYERS_SPACE_SEPARATED> <NONCE> <PRIVATE_KEYS_ARRAY> [EXTRA_ARGS...]"
    echo "Example: $0 \"0xAbc... 0xDef...\" 1234 \"[0x1..., 0x2...]\" --broadcast"
    echo "Note: Arguments can also be provided via .env file variables (IDEAS_LAYERS, NONCE, PRIVATE_KEYS)."
    exit 1
fi

echo "=========================================================="
echo "Unpacking Reform Packages for Ideas Layers"
echo "Nonce: $NONCE"
echo "Layers: $IDEAS_LAYERS"
echo "=========================================================="
echo ""

INDEX=1
TOTAL=$(echo "$IDEAS_LAYERS" | wc -w)

for LAYER in $IDEAS_LAYERS; do
    echo "[$INDEX/$TOTAL] Running unpackReformPackages on: $LAYER"
    forge script governance/actions/Initialise.s.sol:Initialise \
        --sig "unpackReformPackages(address,uint256,uint256[])" \
        "$LAYER" "$NONCE" "$PRIVATE_KEYS" \
        "${EXTRA_ARGS[@]}"
    echo "unpackReformPackages completed for: $LAYER"
    echo ""
    INDEX=$((INDEX + 1))
done

echo "=========================================================="
echo "Unpack Reform Packages Complete! ($TOTAL layers processed)"
echo "=========================================================="
