#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <cannon-log> <rpc-url> <output-json>" >&2
    exit 2
fi

CANNON_LOG=$1
RPC_URL=$2
OUTPUT_JSON=$3
MULTISEND_CALL_ONLY=0x40A2aCCbd92BCA938b02010E17A5b8929b49130D
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pro656-safe-payload.XXXXXX")
TX_LIST="$TMP_DIR/invokes.tsv"
TX_JSON="$TMP_DIR/transactions.json"
trap 'rm -rf "$TMP_DIR"' EXIT

awk '
    /^Executing \[invoke\./ {
        name=$2
        sub(/^\[invoke\./, "", name)
        sub(/\]\.\.\.$/, "", name)
    }
    /Transaction Hash:/ && name != "" {
        print name "\t" $3
        name=""
    }
' "$CANNON_LOG" > "$TX_LIST"

if [ "$(wc -l < "$TX_LIST")" -ne 27 ]; then
    echo "expected 27 provisional invoke transactions, found $(wc -l < "$TX_LIST")" >&2
    exit 1
fi

echo '[]' > "$TX_JSON"
ORDER=0
MULTISEND_BYTES=0x
while IFS=$'\t' read -r NAME TX_HASH; do
    ORDER=$((ORDER + 1))
    TX=$(cast tx "$TX_HASH" --rpc-url "$RPC_URL" --json)
    jq -e '.success == true' >/dev/null <<<"$TX"
    FROM=$(jq -er '.data.from' <<<"$TX")
    TO=$(jq -er '.data.to' <<<"$TX")
    VALUE=$(jq -er '.data.value' <<<"$TX")
    DATA=$(jq -er '.data.input' <<<"$TX")
    BLOCK=$(jq -er '.data.blockNumber' <<<"$TX")

    jq \
        --argjson order "$ORDER" \
        --arg name "$NAME" \
        --arg txHash "$TX_HASH" \
        --arg from "$FROM" \
        --arg to "$TO" \
        --arg value "$VALUE" \
        --arg data "$DATA" \
        --arg blockNumber "$BLOCK" \
        '. + [{order:$order,name:$name,operation:0,txHash:$txHash,from:$from,to:$to,value:$value,data:$data,blockNumber:$blockNumber,dependency:"Cannon DAG; see source TOML"}]' \
        "$TX_JSON" > "$TX_JSON.next"
    mv "$TX_JSON.next" "$TX_JSON"

    TO_RAW=${TO#0x}
    DATA_RAW=${DATA#0x}
    DATA_LENGTH=$(( ${#DATA_RAW} / 2 ))
    VALUE_WORD=$(cast to-uint256 "$VALUE" | sed 's/^0x//')
    LENGTH_WORD=$(cast to-uint256 "$DATA_LENGTH" | sed 's/^0x//')
    MULTISEND_BYTES+="00${TO_RAW}${VALUE_WORD}${LENGTH_WORD}${DATA_RAW}"
done < "$TX_LIST"

MULTISEND_CALLDATA=$(cast calldata 'multiSend(bytes)' "$MULTISEND_BYTES")
ORDERED_PAYLOAD_HASH=$(cast keccak "$MULTISEND_BYTES")
CANONICAL_SHA256=$(jq -c '[.[] | {operation,to,value,data}]' "$TX_JSON" | sha256sum | awk '{print $1}')

mkdir -p "$(dirname "$OUTPUT_JSON")"
jq -n \
    --arg evidenceClass "SYNTHETIC REHEARSAL - NOT PRO-656 ACCEPTANCE EVIDENCE" \
    --arg forkBlock "218500000" \
    --arg multisendCallOnly "$MULTISEND_CALL_ONLY" \
    --arg multisendBytes "$MULTISEND_BYTES" \
    --arg multisendCalldata "$MULTISEND_CALLDATA" \
    --arg orderedPayloadHash "$ORDERED_PAYLOAD_HASH" \
    --arg canonicalTransactionsSha256 "$CANONICAL_SHA256" \
    --slurpfile transactions "$TX_JSON" \
    '{
        evidenceClass:$evidenceClass,
        provisional:true,
        forkBlock:$forkBlock,
        safeTransaction:{to:$multisendCallOnly,value:"0x0",operation:1,data:$multisendCalldata},
        transactionCount:($transactions[0] | length),
        orderedPayloadHash:$orderedPayloadHash,
        canonicalTransactionsSha256:$canonicalTransactionsSha256,
        transactions:$transactions[0]
    }' > "$OUTPUT_JSON"

echo "SYNTHETIC_REHEARSAL_SAFE_PAYLOAD_HASH=$ORDERED_PAYLOAD_HASH"
