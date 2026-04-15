#!/bin/sh
set -e
host=slayer.marioslab.io
host_dir=/home/badlogic/pi.dev
logs_dir=$(mktemp -d)

cleanup() {
    rm -rf "$logs_dir"
}
trap cleanup EXIT INT TERM

rsync -az \
    --include="access.log" \
    --include="access-*.log.gz" \
    --exclude="*" \
    "$host:$host_dir/docker/data/logs/" \
    "$logs_dir/"

combined_log="$logs_dir/all-access.log"
cp "$logs_dir/access.log" "$combined_log"

set -- "$logs_dir"/access-*.log.gz
if [ -e "$1" ]; then
    for file in "$logs_dir"/access-*.log.gz; do
        gzip -cd "$file" >> "$combined_log"
    done
fi

goaccess --keep-last=30 -f "$combined_log" -o report.html --log-format=CADDY

open report.html
