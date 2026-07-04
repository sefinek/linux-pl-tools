#!/bin/bash
# Run from internet:
# bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh)
# bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/ubuntu-mirror-pl/configure-apt-mirror.sh) http://pl.archive.ubuntu.com/ubuntu/
#
# Usage: bash scripts/ubuntu-mirror-pl/configure-apt-mirror.sh
# Other useful script: https://raw.githubusercontent.com/ijash/ubuntu-fastest-mirror/master/run.sh

set -euo pipefail
SECONDS=0

# Logger
log() {
  local level="$1"; shift
  case "$level" in
    info)    echo -e "ℹ️ \033[1;34m$*\033[0m" ;;
    success) echo -e "✅ \033[1;32m$*\033[0m" ;;
    error)   echo -e "❌ \033[1;31m$*\033[0m" ;;
    *)       echo -e "$*";;
  esac
}

# Config
MIRROR_URI="${1:-http://ubuntu.task.gda.pl/ubuntu/}"
SOURCES_DIR="/etc/apt/sources.list.d"
SOURCES_FILE="$SOURCES_DIR/ubuntu.sources"
SOURCES_BACKUP="${SOURCES_FILE}.bak"
LIST_FILE="/etc/apt/sources.list"
LIST_BACKUP="${LIST_FILE}.bak"
KEYRING="/usr/share/keyrings/ubuntu-archive-keyring.gpg"
SUPPORTED_CODENAMES=("noble" "resolute")

# Check lsb_release presence
command -v lsb_release >/dev/null || { log error "lsb_release not found. Install with: sudo apt install lsb-release"; exit 1; }

# Validate Ubuntu codename
DISTRO_CODENAME="$(lsb_release -sc)"
SUPPORTED=false
for codename in "${SUPPORTED_CODENAMES[@]}"; do
  if [[ "$DISTRO_CODENAME" == "$codename" ]]; then
    SUPPORTED=true
    break
  fi
done

if [[ "$SUPPORTED" != true ]]; then
  log error "Supported Ubuntu codenames: ${SUPPORTED_CODENAMES[*]} (got: $DISTRO_CODENAME)"
  exit 1
fi

# Extract hostname from MIRROR_URI
MIRROR_HOST=$(echo "$MIRROR_URI" | awk -F/ '{print $3}')

# ICMP ping test (3 seconds)
if command -v ping >/dev/null; then
  log info "Pinging host: $MIRROR_HOST [3s]"
  if PING_OUT=$(ping -c 3 -W 3 "$MIRROR_HOST" 2>/dev/null); then
    PING_AVG=$(echo "$PING_OUT" | awk -F'/' '/^rtt/ {printf "%.0f", $5}')
    log success "Ping average: ${PING_AVG}ms"
  else
    log error "Mirror host is unreachable via ICMP (ping)"
    exit 1
  fi
else
  log info "Skipping ping test — 'ping' command not available"
fi

# Validate APT sources dir
if [[ ! -d "$SOURCES_DIR" ]]; then
  log error "Missing APT sources directory: $SOURCES_DIR"
  exit 1
fi

# Check for keyring
if [[ ! -f "$KEYRING" ]]; then
  log error "Missing keyring: $KEYRING"
  echo "   Try: sudo apt install ubuntu-keyring"
  exit 1
fi

# Backup and clean sources.list
if [[ -f "$LIST_FILE" ]]; then
  log info "Backing up $LIST_FILE -> $LIST_BACKUP"
  sudo cp "$LIST_FILE" "$LIST_BACKUP"
  log info "Removing archive.ubuntu.com entries from $LIST_FILE"
  sudo sed -i '/^deb .*archive\.ubuntu\.com/Id' "$LIST_FILE"
fi

# Backup existing .sources file
if [[ -f "$SOURCES_FILE" ]]; then
  log info "Backing up $SOURCES_FILE -> $SOURCES_BACKUP"
  sudo cp "$SOURCES_FILE" "$SOURCES_BACKUP"
fi

# Write new mirror config
log info "Setting APT mirror to: $MIRROR_URI"
sudo tee "$SOURCES_FILE" > /dev/null <<EOF
Types: deb
URIs: $MIRROR_URI
Suites: $DISTRO_CODENAME $DISTRO_CODENAME-updates $DISTRO_CODENAME-backports
Components: main restricted universe multiverse
Signed-By: $KEYRING

Types: deb
URIs: $MIRROR_URI
Suites: $DISTRO_CODENAME-security
Components: main restricted universe multiverse
Signed-By: $KEYRING
EOF

# Clean APT cache
log info "Cleaning APT cache..."
sudo apt clean

# Update APT index
log info "Running apt update..."
if sudo apt update; then
  log success "Mirror updated successfully! Finished in ${SECONDS}s."
else
  log error "apt update failed! Check your network or mirror availability. Total execution time: ${SECONDS}s"
  exit 2
fi
