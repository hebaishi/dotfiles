#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 'command to run'"
    exit 1
fi

command="$@"
echo "Will run: $command"
echo "Press Enter to execute (Ctrl+C to exit)"

while true; do
    read
    eval "$command"
done
