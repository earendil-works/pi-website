#!/bin/bash
set -e

mkdir -p data

PORT=${PORT:-8080}
BLARGH_PORT=${BLARGH_PORT:-8081}

cleanup() {
    if [ -n "$server_pid" ]; then
        kill $server_pid 2>/dev/null || true
    fi
    if [ -n "$blargh_pid" ]; then
        kill $blargh_pid 2>/dev/null || true
    fi
}

trap cleanup EXIT INT TERM

blargh --in src --out html --watch --serve $BLARGH_PORT &
blargh_pid=$!

PORT=$PORT COUNTS_PATH=./data/install-counts.json DEV_PROXY_TARGET=http://127.0.0.1:$BLARGH_PORT node ./server/install-counter.mjs &
server_pid=$!

while kill -0 $server_pid 2>/dev/null && kill -0 $blargh_pid 2>/dev/null; do
    sleep 1
done
