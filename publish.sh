#!/bin/bash
set -e

rm -rf html
blargh --in src --out html

host=slayer.marioslab.io
host_dir=/home/badlogic/pi.dev

current_date=$(date "+%Y-%m-%d %H:%M:%S")
commit_hash=$(git rev-parse HEAD)
echo "{\"date\": \"$current_date\", \"commit\": \"$commit_hash\"}" > html/version.json

ssh -t $host "mkdir -p $host_dir/docker/data/logs"
rsync -avz --exclude node_modules --exclude .git --exclude data --exclude docker/data ./ $host:$host_dir

echo "Restarting service..."
ssh $host "cd $host_dir && ./docker/control.sh stop && ./docker/control.sh start"
echo "Tailing logs for 5 seconds..."
ssh $host "cd $host_dir && ./docker/control.sh logs" &
pid=$!
sleep 5
kill $pid 2>/dev/null || true
echo "Done."
