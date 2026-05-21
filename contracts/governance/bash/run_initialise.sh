#!/bin/bash
# Stateful initialisation runner for Cultural Stewards DAO.
#
# Calls InitialiseRunner.run() repeatedly, waiting between invocations, until
# the runner logs "initialisation complete!". The runner itself reads on-chain
# state to determine which phases are done and what still needs to execute —
# there is no step-specific logic here.
#
# Usage:
#   ./run_initialise.sh <PRIMARY_LAYER> <DIGITAL_LAYER> <NONCE> <IDEAS_NAMES> <PRIVATE_KEYS> [EXTRA_ARGS...]
#
# Arguments can also be supplied via .env variables:
#   PRIMARY_LAYER, DIGITAL_LAYER, NONCE, IDEAS_NAMES, PRIVATE_KEYS
#
# EXTRA_ARGS are forwarded to every forge script call (e.g. --broadcast --rpc-url $RPC).

cd "$(dirname "$0")/../.."

set -e

if [ -f .env ]; then
    set -a; source .env; set +a
fi

PRIMARY_LAYER="${1:-$PRIMARY_LAYER}"
DIGITAL_LAYER="${2:-$DIGITAL_LAYER}"
NONCE="${3:-$NONCE}"
IDEAS_NAMES="${4:-$IDEAS_NAMES}"
PRIVATE_KEYS="${5:-$PRIVATE_KEYS}"
EXTRA_ARGS=("${@:6}")

if [ -z "$PRIMARY_LAYER" ] || [ -z "$DIGITAL_LAYER" ] || [ -z "$NONCE" ] || [ -z "$IDEAS_NAMES" ] || [ -z "$PRIVATE_KEYS" ]; then
    echo "Error: missing required arguments."
    echo "Usage: $0 <PRIMARY_LAYER> <DIGITAL_LAYER> <NONCE> <IDEAS_NAMES> <PRIVATE_KEYS> [EXTRA_ARGS...]"
    echo "Example: $0 0x123... 0xabc... 1 \"[Seeing,Making]\" \"[key1,key2]\" --broadcast"
    exit 1
fi

# How long to wait between run() calls (seconds). Adjust to match your chain's block time
# and shortest expected voting/timelock window. Overshooting is safe — the runner skips
# phases that are already complete.
POLL_INTERVAL="${POLL_INTERVAL:-420}"

echo "=========================================================="
echo "Cultural Stewards — Initialisation Runner"
echo "Primary Layer:  $PRIMARY_LAYER"
echo "Digital Layer:  $DIGITAL_LAYER"
echo "Nonce:          $NONCE"
echo "Ideas Layers:   $IDEAS_NAMES"
echo "Poll interval:  ${POLL_INTERVAL}s"
echo "=========================================================="

ATTEMPT=1
while true; do
    echo ""
    echo "--- Attempt $ATTEMPT ($(date '+%H:%M:%S')) ---"

    OUTPUT=$(forge script governance/actions/InitialiseRunner.s.sol:InitialiseRunner \
        --sig "run(address,address,uint256,string[],uint256[])" \
        "$PRIMARY_LAYER" "$DIGITAL_LAYER" "$NONCE" "$IDEAS_NAMES" "$PRIVATE_KEYS" \
        "${EXTRA_ARGS[@]}" 2>&1)

    echo "$OUTPUT"

    if echo "$OUTPUT" | grep -q "initialisation complete"; then
        echo ""
        echo "=========================================================="
        echo "Initialisation complete!"
        echo "=========================================================="
        exit 0
    fi

    echo ""
    echo "Waiting ${POLL_INTERVAL}s before next attempt..."
    sleep "$POLL_INTERVAL"
    ATTEMPT=$((ATTEMPT + 1))
done
