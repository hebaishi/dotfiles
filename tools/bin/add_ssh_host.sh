#!/bin/bash

# Default values
DEFAULT_KEY="$HOME/.ssh/id_rsa.pub"
DEFAULT_PORT=22

# Function to display usage
usage() {
    echo "Usage: $0 [-k key_path] [-n host_nickname] user@host [-P port]"
    echo "Options:"
    echo "  -k    Path to public key (default: ~/.ssh/id_rsa.pub)"
    echo "  -n    Nickname for the host in ssh config"
    echo "  -P    Port number (default: 22)"
    exit 1
}

# Parse command line arguments
while getopts "k:n:P:h" opt; do
    case $opt in
        k) KEY_PATH="$OPTARG" ;;
        n) NICKNAME="$OPTARG" ;;
        P) PORT="$OPTARG" ;;
        h) usage ;;
        \?) usage ;;
    esac
done

# Shift past the options
shift $((OPTIND-1))

# Check if user@host is provided
if [ -z "$1" ]; then
    echo "Error: Please provide user@host"
    usage
fi

# Parse user@host
USER_HOST="$1"
if [[ ! "$USER_HOST" =~ ^[^@]+@[^@]+$ ]]; then
    echo "Error: Invalid format. Please use user@host"
    exit 1
fi

# Extract user and host
USER="${USER_HOST%@*}"
HOST="${USER_HOST#*@}"

# Set defaults if not provided
KEY_PATH="${KEY_PATH:-$DEFAULT_KEY}"
PORT="${PORT:-$DEFAULT_PORT}"
NICKNAME="${NICKNAME:-$HOST}"

# Check if key exists
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: Public key not found at $KEY_PATH"
    exit 1
fi

# Copy SSH key to remote host
echo "Copying SSH key to remote host..."
ssh-copy-id -i "$KEY_PATH" -p "$PORT" "$USER_HOST"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy SSH key"
    exit 1
fi

# Create or update SSH config
CONFIG="$HOME/.ssh/config"
touch "$CONFIG"

# Check if host entry already exists
if grep -q "^Host $NICKNAME\$" "$CONFIG"; then
    echo "Warning: Host '$NICKNAME' already exists in config. Skipping config update."
else
    # Add new host entry
    echo -e "\nHost $NICKNAME\n    HostName $HOST\n    User $USER\n    Port $PORT\n    IdentityFile ${KEY_PATH%.pub}" >> "$CONFIG"
    echo "Successfully added host '$NICKNAME' to SSH config"
    echo "You can now connect using: ssh $NICKNAME"
fi
