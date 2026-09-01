#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]; then
    echo "usage: $0 <reference-rpc> <upstream-rpc> <safe-payload-json> <output-json> [fresh-port]" >&2
    exit 2
fi

REFERENCE_RPC=$1
UPSTREAM_RPC=$2
PAYLOAD_JSON=$3
OUTPUT_JSON=$4
FRESH_PORT=${5:-18549}
FRESH_RPC="http://127.0.0.1:${FRESH_PORT}"
FORK_BLOCK=218500000
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pro656-safe-replay.XXXXXX")
ANVIL_LOG="$TMP_DIR/anvil.log"
DEPLOY_TXS="$TMP_DIR/deploy-transactions.jsonl"
RESULTS="$TMP_DIR/results.json"
ANVIL_PID=""

cleanup() {
    if [ -n "$ANVIL_PID" ] && kill -0 "$ANVIL_PID" >/dev/null 2>&1; then
        kill "$ANVIL_PID" >/dev/null 2>&1 || true
        wait "$ANVIL_PID" >/dev/null 2>&1 || true
    fi
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if cast chain-id --rpc-url "$FRESH_RPC" >/dev/null 2>&1; then
    echo "port ${FRESH_PORT} already serves RPC" >&2
    exit 1
fi

anvil \
    --fork-url "$UPSTREAM_RPC" \
    --fork-block-number "$FORK_BLOCK" \
    --chain-id 1729 \
    --port "$FRESH_PORT" \
    --auto-impersonate > "$ANVIL_LOG" 2>&1 &
ANVIL_PID=$!

for _ in $(seq 1 120); do
    cast chain-id --rpc-url "$FRESH_RPC" >/dev/null 2>&1 && break
    sleep 1
done
cast chain-id --rpc-url "$FRESH_RPC" >/dev/null

receipt_status() {
    local tx_hash=$1
    local receipt
    for _ in $(seq 1 120); do
        receipt=$(cast receipt "$tx_hash" --rpc-url "$FRESH_RPC" --json 2>/dev/null || true)
        if [ -n "$receipt" ] && [ "$(jq -r '.status // empty' <<<"$receipt")" != "" ]; then
            jq -r '.status' <<<"$receipt"
            return
        fi
        sleep 1
    done
    echo "missing receipt for ${tx_hash}" >&2
    return 1
}

send_reference_tx() {
    local tx=$1
    local from to data value gas request hash status
    jq -e '.success == true' >/dev/null <<<"$tx"
    from=$(jq -er '.data.from' <<<"$tx")
    to=$(jq -r '.data.to // empty' <<<"$tx")
    data=$(jq -er '.data.input' <<<"$tx")
    value=$(jq -er '.data.value' <<<"$tx")
    gas=$(jq -er '.data.gas' <<<"$tx")
    cast rpc --rpc-url "$FRESH_RPC" anvil_setBalance "$from" 0x3635c9adc5dea00000 >/dev/null
    if [ -n "$to" ]; then
        request=$(jq -nc --arg from "$from" --arg to "$to" --arg data "$data" --arg value "$value" --arg gas "$gas" \
            '{from:$from,to:$to,data:$data,value:$value,gas:$gas}')
    else
        request=$(jq -nc --arg from "$from" --arg data "$data" --arg value "$value" --arg gas "$gas" \
            '{from:$from,data:$data,value:$value,gas:$gas}')
    fi
    hash=$(cast rpc --rpc-url "$FRESH_RPC" eth_sendTransaction "$request" | tr -d '"')
    status=$(receipt_status "$hash")
    if [ "$status" != "0x1" ]; then
        echo "reference transaction ${hash} reverted" >&2
        return 1
    fi
}

send_payload_range() {
    local first=$1
    local last=$2
    local idx tx_hash tx
    if [ "$first" -gt "$last" ]; then return; fi
    for idx in $(seq "$first" "$last"); do
        tx_hash=$(jq -er ".transactions[$((idx - 1))].txHash" "$PAYLOAD_JSON")
        tx=$(cast tx "$tx_hash" --rpc-url "$REFERENCE_RPC" --json)
        send_reference_tx "$tx"
    done
}

FIRST_INVOKE_BLOCK_HEX=$(jq -er '.transactions[0].blockNumber' "$PAYLOAD_JSON")
FIRST_INVOKE_BLOCK=$(cast to-dec "$FIRST_INVOKE_BLOCK_HEX")
: > "$DEPLOY_TXS"
for block in $(seq $((FORK_BLOCK + 1)) $((FIRST_INVOKE_BLOCK - 1))); do
    cast block "$block" --full --rpc-url "$REFERENCE_RPC" --json \
        | jq -c '.data.transactions[] | {schema_version:1,success:true,data:.,errors:[],warnings:[]}' \
        >> "$DEPLOY_TXS"
done

while IFS= read -r tx; do
    send_reference_tx "$tx"
done < "$DEPLOY_TXS"

BASE_SNAPSHOT=$(cast rpc --rpc-url "$FRESH_RPC" evm_snapshot | tr -d '"')
echo '[]' > "$RESULTS"

BOUNDARIES=(upgrade_core_proxy upgrade_orders_gateway_proxy upgrade_passive_perp_proxy upgrade_periphery_proxy)
PROXIES=(
    0xA763B6a5E09378434406C003daE6487FbbDc1a80
    0xfc8c96bE87Da63CeCddBf54abFA7B13ee8044739
    0x27E5cb712334e101B3c232eB0Be198baaa595F5F
    0xCd2869d1eb1BC8991Bc55de9E9B779e912faF736
)

for boundary_position in "${!BOUNDARIES[@]}"; do
    boundary=${BOUNDARIES[$boundary_position]}
    proxy=${PROXIES[$boundary_position]}
    boundary_order=$(jq -er --arg name "$boundary" '.transactions[] | select(.name == $name) | .order' "$PAYLOAD_JSON")

    send_payload_range 1 $((boundary_order - 1))
    implementation_before=$(cast call "$proxy" 'getImplementation()(address)' --rpc-url "$FRESH_RPC")

    # Substitute a zero-address upgrade at the exact boundary. The Safe driver observes status=0 and sends nothing
    # later until explicitly resumed; this is the rehearsal's deterministic failure injection.
    sender=$(jq -er ".transactions[$((boundary_order - 1))].from" "$PAYLOAD_JSON")
    bad_data=$(cast calldata 'upgradeTo(address)' 0x0000000000000000000000000000000000000000)
    cast rpc --rpc-url "$FRESH_RPC" anvil_setBalance "$sender" 0x3635c9adc5dea00000 >/dev/null
    bad_request=$(jq -nc --arg from "$sender" --arg to "$proxy" --arg data "$bad_data" \
        '{from:$from,to:$to,data:$data,value:"0x0",gas:"0x989680"}')
    bad_hash=$(cast rpc --rpc-url "$FRESH_RPC" eth_sendTransaction "$bad_request" | tr -d '"')
    bad_status=$(receipt_status "$bad_hash")
    if [ "$bad_status" != "0x0" ]; then
        echo "failure injection unexpectedly succeeded at ${boundary}" >&2
        exit 1
    fi

    implementation_after_failure=$(cast call "$proxy" 'getImplementation()(address)' --rpc-url "$FRESH_RPC")
    if [ "$implementation_after_failure" != "$implementation_before" ]; then
        echo "failed boundary mutated ${proxy}" >&2
        exit 1
    fi

    send_payload_range "$boundary_order" 27
    for final_proxy in "${PROXIES[@]}"; do
        reference_impl=$(cast call "$final_proxy" 'getImplementation()(address)' --rpc-url "$REFERENCE_RPC")
        replay_impl=$(cast call "$final_proxy" 'getImplementation()(address)' --rpc-url "$FRESH_RPC")
        if [ "${reference_impl,,}" != "${replay_impl,,}" ]; then
            echo "halt/resume final implementation mismatch for ${final_proxy}" >&2
            exit 1
        fi
    done

    jq \
        --arg boundary "$boundary" \
        --argjson order "$boundary_order" \
        --arg failedTxHash "$bad_hash" \
        --arg implementationBefore "$implementation_before" \
        --arg implementationAfterFailure "$implementation_after_failure" \
        '. + [{boundary:$boundary,order:$order,injectedStatus:"0x0",failedTxHash:$failedTxHash,haltedWithoutMutation:true,resumedRemainingPayload:true,implementationBefore:$implementationBefore,implementationAfterFailure:$implementationAfterFailure,finalImplementationParity:true}]' \
        "$RESULTS" > "$RESULTS.next"
    mv "$RESULTS.next" "$RESULTS"

    cast rpc --rpc-url "$FRESH_RPC" evm_revert "$BASE_SNAPSHOT" >/dev/null
    BASE_SNAPSHOT=$(cast rpc --rpc-url "$FRESH_RPC" evm_snapshot | tr -d '"')
done

mkdir -p "$(dirname "$OUTPUT_JSON")"
jq -n \
    --arg evidenceClass "SYNTHETIC REHEARSAL - NOT PRO-656 ACCEPTANCE EVIDENCE" \
    --arg forkBlock "$FORK_BLOCK" \
    --arg payloadHash "$(jq -er '.orderedPayloadHash' "$PAYLOAD_JSON")" \
    --argjson deploymentTransactions "$(wc -l < "$DEPLOY_TXS")" \
    --slurpfile boundaries "$RESULTS" \
    '{evidenceClass:$evidenceClass,provisional:true,forkBlock:$forkBlock,payloadHash:$payloadHash,deploymentTransactionsReplayed:$deploymentTransactions,boundaries:$boundaries[0]}' \
    > "$OUTPUT_JSON"

echo "SYNTHETIC_REHEARSAL_SAFE_BOUNDARIES=4"
