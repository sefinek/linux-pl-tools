#!/usr/bin/env bash
#
# Locale Configuration Script for Ubuntu/Debian Systems
# Run from internet:
# bash <(curl -fsSL https://raw.githubusercontent.com/sefinek/linux-pl-tools/main/scripts/set-locale-pl-en/configure-locale.sh)
#
# This script configures a hybrid locale setup:
# - System language: English (en_US.UTF-8) - for messages and interface
# - Regional formats: Polish (pl_PL.UTF-8) - for dates, numbers, currency, paper size, etc...
#
# Usage: bash scripts/set-locale-pl-en/configure-locale.sh
#

set -euo pipefail

# Check if running as root and set sudo prefix accordingly
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

# Verify the script is running on a Debian-based system
if ! command -v apt-get >/dev/null 2>&1; then
  echo "Error: This script requires apt-get (Debian/Ubuntu)" >&2
  exit 1
fi

# Ensure the 'locales' package is installed
if ! dpkg -s locales >/dev/null 2>&1; then
  echo "Installing 'locales' package..."
  ${SUDO} apt-get update -qq
  ${SUDO} apt-get install -y locales
  echo
fi

# Display current locale and timezone settings
echo "--- Current Settings ---"
locale
date
echo

# Configure timezone to Europe/Warsaw (Central European Time)
${SUDO} timedatectl set-timezone Europe/Warsaw

# Uncomment required locales in /etc/locale.gen (needed for Debian/Proxmox)
${SUDO} sed -i 's/^# *en_US\.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
${SUDO} sed -i 's/^# *pl_PL\.UTF-8 UTF-8/pl_PL.UTF-8 UTF-8/' /etc/locale.gen

# Generate locale files from /etc/locale.gen
${SUDO} locale-gen

# Configure system-wide locale preferences
# English: Interface language, messages, text handling, sorting
# Polish: Time format, numbers, currency, paper size, phone numbers, etc.
${SUDO} update-locale \
  LANG=en_US.UTF-8 \
  LC_MESSAGES=en_US.UTF-8 \
  LC_CTYPE=en_US.UTF-8 \
  LC_COLLATE=en_US.UTF-8 \
  LC_TIME=pl_PL.UTF-8 \
  LC_NUMERIC=pl_PL.UTF-8 \
  LC_MONETARY=pl_PL.UTF-8 \
  LC_PAPER=pl_PL.UTF-8 \
  LC_MEASUREMENT=pl_PL.UTF-8 \
  LC_NAME=pl_PL.UTF-8 \
  LC_ADDRESS=pl_PL.UTF-8 \
  LC_TELEPHONE=pl_PL.UTF-8 \
  LC_IDENTIFICATION=pl_PL.UTF-8 \
  LC_ALL=""

# Apply locale changes to the current shell session
if [ -f /etc/default/locale ]; then
  set -a
  . /etc/default/locale
  set +a
fi

# Display updated locale and timezone settings
echo
echo "--- Updated Settings ---"
locale
date

echo
echo "Note: For changes to apply globally, open a new terminal session or run: exec bash"
