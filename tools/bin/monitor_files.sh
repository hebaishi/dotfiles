#!/bin/bash

# Check if inotify-tools is installed
if ! command -v inotifywait &> /dev/null; then
    echo "inotify-tools is not installed. Please install it first:"
    echo "  For Debian/Ubuntu: sudo apt-get install inotify-tools"
    echo "  For RHEL/CentOS/Fedora: sudo yum install inotify-tools"
    exit 1
fi

# Command to run when changes are detected
COMMAND_TO_RUN="$1"

# Check if command is provided
if [ -z "$COMMAND_TO_RUN" ]; then
    echo "Usage: $0 <command_to_run> <file_or_dir1> [file_or_dir2] [file_or_dir3] ..."
    exit 1
fi

# Shift to get the list of files/directories
shift
PATHS_TO_WATCH=("$@")

# Check if at least one path is provided
if [ ${#PATHS_TO_WATCH[@]} -eq 0 ]; then
    echo "Usage: $0 <command_to_run> <file_or_dir1> [file_or_dir2] [file_or_dir3] ..."
    exit 1
fi

# Validate all paths exist
for path in "${PATHS_TO_WATCH[@]}"; do
    if [ ! -e "$path" ]; then
        echo "Error: Path '$path' does not exist."
        exit 1
    fi
done

echo "Monitoring the following paths for changes:"
for path in "${PATHS_TO_WATCH[@]}"; do
    if [ -d "$path" ]; then
        echo "  Directory: $path"
    else
        echo "  File: $path"
    fi
done
echo "When changes occur, will run: $COMMAND_TO_RUN"
echo "Press Ctrl+C to stop monitoring."

# Monitor the paths for modifications
while true; do
    inotifywait -r -e modify,create,delete,move "${PATHS_TO_WATCH[@]}"
    echo "Change detected. Running command: $COMMAND_TO_RUN"
    eval "$COMMAND_TO_RUN"
done
