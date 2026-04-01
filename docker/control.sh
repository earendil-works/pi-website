#!/bin/bash

set -e

project=pi-ai

printHelp () {
    echo "Usage: control.sh <command>"
    echo "Available commands:"
    echo
    echo "   start        Builds and starts the service"
    echo "   stop         Stops the service"
    echo "   logs         Tail -f service logs"
    echo "   shell        Opens a shell into the container"
}

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
pushd $dir > /dev/null

mkdir -p data/logs

case "$1" in
start)
    docker compose -p $project build
    docker compose -p $project up -d
    ;;
stop)
    docker compose -p $project down -t 1
    ;;
shell)
    docker exec -it ${project}-web-1 sh
    ;;
logs)
    docker compose -p $project logs -f
    ;;
*)
    echo "Invalid command $1"
    printHelp
    ;;
esac

popd > /dev/null
